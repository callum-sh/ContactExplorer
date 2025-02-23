const express = require('express');
const axios = require('axios');

// ensure db is connected 
const pool = require('./db');
require('dotenv').config();

const app = express();
const port = process.env.PORT || 3000;

app.use(express.json());

app.get('/', (req, res) => {
    res.send("Hello from Tether"); 
});


/**
 * Embed a contact in the database 
 */
app.post('/embedContact', async (req, res) => {
    const { name, email, company, notes, meta } = req.body;
    console.log(`embedding contact: ${name}, ${email}, ${company}, ${notes}, ${meta}`);

    try {
        // create embedding for given contact 
        const result = await createAndEmbedContact(name, email, company, notes, meta);
        res.json(result);

    } catch (error) {
        console.error('Error embedding contact:', error.response?.data || error);
        res.status(500).json({ error: 'Error embedding contact' });
    }
});


/**
 * Query embedding space for contact best matching query 
 */
app.post('/query', async (req, res) => {
    const { query } = req.body;

    // save query (w/ datetime) to db for recent captures
    try {
        const result = await pool.query(
            'INSERT INTO queries (query) VALUES ($1) RETURNING *',
            [query]
        );
        console.log('Saved query:', result.rows[0]);
    } catch (error) {
        console.error('Error saving query:', error);
    }

    // TODO: do more dynamic 
    const isTask = query.toLowerCase().includes('remind') || query.toLowerCase().includes('schedule');

    // create task with 1 sentence summary of query
    if (isTask) {
      const prompt = `
      Given the following query, generate a short and concise summary:
      Query: "${query}"
      `.trim();

      try {
        const response = await axios.post(
          'https://api.cohere.ai/generate',
          {
            model: 'command-xlarge-nightly',
            prompt: prompt,
            max_tokens: 20,
            temperature: 0.7,
            k: 0,
            p: 0.75,
            frequency_penalty: 0,
            presence_penalty: 0,
            stop_sequences: []
          },
          {
            headers: {
              'Authorization': `Bearer ${process.env.COHERE_API_KEY}`,
              'Content-Type': 'application/json'
            }
          }
        );
        const summary = response.data.text.trim();
        console.log('Task summary:', summary);

        // get dynamic date if mentioned in query, otherwise use current date
        const datePrompt = `
        Extract a full date in strict ISO 8601 format (YYYY-MM-DDTHH:MM:SSZ) from the following query.
        Return only the extracted date with no extra words.
        If no date is mentioned, return "NONE".
        Query: "${query}"
        `;

        const dateResponse = await axios.post(
          'https://api.cohere.ai/generate',
          {
            model: 'command-xlarge-nightly',
            prompt: datePrompt,
            max_tokens: 5,
            temperature: 0.0,
            stop_sequences: []
          },
          {
            headers: {
              'Authorization': `Bearer ${process.env.COHERE_API_KEY}`,
              'Content-Type': 'application/json'
            }
          }
        );
        let dynamicDate = dateResponse.data.text.trim();
        console.log('✅ Dynamic date from prompt:', dynamicDate);

        if (dynamicDate === "NONE" || !/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$/.test(dynamicDate)) {
          dynamicDate = new Date().toISOString(); // ✅ Use current date if invalid
        }

        // save task to db 
        const result = await pool.query(
          'INSERT INTO tasks (task, date) VALUES ($1, $2) RETURNING *',
          [summary, dynamicDate]
        );
        console.log('Saved task:', result.rows[0]);

        // add summary of creating task to response
        const taskCreationPrompt = `
        Give me a concise summary of the task you just created.
        Task: "${summary}"
        `;
        const taskCreationResponse = await axios.post(
          'https://api.cohere.ai/generate',
          {
            model: 'command-xlarge-nightly',
            prompt: taskCreationPrompt,
            max_tokens: 20,
            temperature: 0.7,
            k: 0,
            p: 0.75,
            frequency_penalty: 0,
            presence_penalty: 0,
            stop_sequences: []
          },
          {
            headers: {
              'Authorization': `Bearer ${process.env.COHERE_API_KEY}`,
              'Content-Type': 'application/json'
            }
          }
        );
        const taskSummary = taskCreationResponse.data.text.trim();
        console.log('Task summary:', taskSummary);

        return res.json({ isTask: true, task: result.rows[0], summary: taskSummary });
      } catch (error) {
        console.error('Error generating task summary:', error.response?.data || error);
        return res.status(500).json({ error: 'Error generating task summary' });
      }
    }


    const isNewContact = await classifyNewContactQuery(query);

    if (isNewContact) {
      // create new contact and embed it 
      // fit description to { name, email, company, notes, meta }
      const { name, email, company, notes, meta } = await generateContactDescription(query);
      const newContact = await createAndEmbedContact(name, email, company, notes, meta);

      // create summary of new contact
      const prompt = `
      Given the following contact details, generate an EXTREMELY CONCISEsummary that highlights key information:
      Name: ${name}
      Email: ${email}
      Company: ${company}
      Notes: ${notes}
      Additional Info: ${meta || ''}
      Query: ${query}
      `.trim();

      const summaryResponse = await axios.post(
        'https://api.cohere.ai/generate',
        {
          model: 'command-xlarge-nightly',
          prompt: prompt,
          max_tokens: 20,
          temperature: 0.7,
          k: 0,
          p: 0.75,
          frequency_penalty: 0,
          presence_penalty: 0,
          stop_sequences: []
        },
        {
          headers: {
            'Authorization': `Bearer ${process.env.COHERE_API_KEY}`,
            'Content-Type': 'application/json'
          }
        }
      );
      console.log('Summary response:', summaryResponse.data);
      const summary = summaryResponse.data.text.trim();

      res.json({
        isNewContact: true,
        contact: newContact.rows[0],
        summary
      });
    }

    // not new contact; query existing contacts for best match
    try {
        // get embedded query 
        const embedResponse = await axios.post('https://api.cohere.ai/embed', {
          texts: [query]
        }, {
          headers: {
            'Authorization': `Bearer ${process.env.COHERE_API_KEY}`,
            'Content-Type': 'application/json'
          }
        });
        const queryEmbedding = embedResponse.data.embeddings[0];
    
        // get all embeddings 
        // TODO: do user specific 
        const contactsResult = await pool.query('SELECT * FROM contacts');
        const contacts = contactsResult.rows;
    
        // find best matching contact to given query based on cosine sim 
        let bestMatch = null, highestSimilarity = -1;

        for (const contact of contacts) {
          const contactEmbedding = JSON.parse(contact.embedding);
          const similarity = cosineSimilarity(queryEmbedding, contactEmbedding);
          
          if (similarity > highestSimilarity) {
            highestSimilarity = similarity, bestMatch = contact;
          }
        }
    
        if (!bestMatch) {
          return res.status(404).json({ error: 'No matching contact found' });
        }

        // derive and update contact notes to include new information provided in the query, if necessary 
        const queryNewInfo = await axios.post('https://api.cohere.ai/generate', {
            model: 'command-xlarge-nightly',
            prompt: `Given the following contact details, extract any new information from the query about the person of person in question:
            Name: ${bestMatch.name}
            Company: ${bestMatch.company}
            Notes: ${bestMatch.notes}

            Query: ${query}. IF THERE IS NOT ANY GOOD NEW INFORMATION ONLY FROM THE QUERY, RETURN AN EMPTY STRING`.trim(),
            max_tokens: 100,
            temperature: 0.3,
            stop_sequences: []
        }, {
            headers: {
                'Authorization': `Bearer ${process.env.COHERE_API_KEY}`,
                'Content-Type': 'application/json'
            }
        });

        let newNotes = bestMatch.notes;
        if (queryNewInfo.data.text.trim() !== '') {
           newNotes += queryNewInfo.data.text.trim();
        }

        await pool.query(
          'UPDATE contacts SET notes = $1 WHERE id = $2',
          [newNotes, bestMatch.id]
        );

        // call llm to generate summary of interactions 
        const prompt = `Given the following contact details, generate a spoken summary that highlights key information:
            Name: ${bestMatch.name}
            Company: ${bestMatch.company}
            Notes: ${newNotes, bestMatch.notes}

            for the given query ${query}.

            Speak as if you're summarizing the encounter I had with her. Use you, not I.`.trim();

        const summaryResponse = await axios.post('https://api.cohere.ai/generate', {
            model: 'command-xlarge-nightly',
            prompt: prompt,
            max_tokens: 100,
            temperature: 0.7,
            k: 0,
            p: 0.75,
            frequency_penalty: 0,
            presence_penalty: 0,
            stop_sequences: []
        }, {
            headers: {
                'Authorization': `Bearer ${process.env.COHERE_API_KEY}`,
                'Content-Type': 'application/json'
            }
        });
        console.log('Summary response:', summaryResponse.data);
        const summary = summaryResponse.data.text.trim();
            
        res.json({
          isNewContact: false,
          contact: bestMatch,
          summary,
          similarity: highestSimilarity
        });

      } catch (error) {
        console.error('Error querying contact:', error.response?.data || error);
        res.status(500).json({ error: 'Error querying contact' });
      }
    }
);

/**
 * Get the n most recent queries 
 */
app.get('/recentQueries', async (req, res) => {
    const n = req.query.n || 15;
    try {
        const result = await pool.query('SELECT * FROM queries ORDER BY created_at DESC LIMIT $1', [n]);
        res.json(result.rows);
    } catch (error) {
        console.error('Error getting recent queries:', error);
        res.status(500).json({ error: 'Error getting recent queries' });
    }
});


/**
 * Get the n upcoming tasks  
 */
app.get('/upcomingTasks', async (req, res) => {
  const n = req.query.n || 15;
  try {
      const result = await pool.query('SELECT * FROM tasks ORDER BY date ASC LIMIT $1', [n]);
      res.json(result.rows);
  } catch (error) {
      console.error('Error getting recent queries:', error);
      res.status(500).json({ error: 'Error getting recent queries' });
  }
});





// Start the server
app.listen(port, () => {
  console.log(`Server running on port ${port}`);
});


// HELPERS ===================================================================================================================

const cosineSimilarity = (vecA, vecB) => {
    const dotProduct = vecA.reduce((acc, val, idx) => acc + val * vecB[idx], 0);
    const normA = Math.sqrt(vecA.reduce((acc, val) => acc + val * val, 0));
    const normB = Math.sqrt(vecB.reduce((acc, val) => acc + val * val, 0));
    return dotProduct / (normA * normB);
};

const classifyNewContactQuery = async (query) => {
  const prompt = `
  Determine if the following query is describing a new contact:
  Query: "${query}"
  Answer with "yes" if it's a new contact (e.g., "I just met...", "first time meeting...", "met for the first time") or "no" otherwise.
  `;
  try {
    const response = await axios.post(
      'https://api.cohere.ai/generate',
      {
        model: 'command-xlarge-nightly',
        prompt: prompt,
        max_tokens: 5,
        temperature: 0.0, // deterministic 
        stop_sequences: []
      },
      {
        headers: {
          'Authorization': `Bearer ${process.env.COHERE_API_KEY}`,
          'Content-Type': 'application/json'
        }
      }
    );
    const answer = response.data.text.trim().toLowerCase();
    console.log(answer)
    return answer === 'yes';
  } catch (error) {
    console.error('Error classifying query:', error.response?.data || error.message);
    return false;
  }
};

async function createAndEmbedContact(name, email, company, notes, meta) {
  const textForEmbedding = `Name: ${name}. Email: ${email}. Company: ${company}. Notes: ${notes}. Additional Info: ${meta || ''}`;

  const response = await axios.post('https://api.cohere.ai/embed', {
    texts: [textForEmbedding]
  }, {
    headers: {
      'Authorization': `Bearer ${process.env.COHERE_API_KEY}`,
      'Content-Type': 'application/json'
    }
  });

  // save embedded contact into db 
  const embeddings = response.data.embeddings;
  const embeddingVector = embeddings[0];
  const result = await pool.query(
    'INSERT INTO contacts (name, email, company, notes, embedding) VALUES ($1, $2, $3, $4, $5) RETURNING *',
    [name, email, company, notes, JSON.stringify(embeddingVector)]
  );
  return result;
}

/**
 * Format query into { name, email, company, notes, meta } as best as possible
 */
async function generateContactDescription(query) {
  const prompt = `
  Extract the following contact details from the query below.
  Return only a JSON object with the keys "name", "email", "company", "notes", and "meta". 
  If any value is missing in the query, set that field to an empty string.
  Do not include any additional text or explanation.

  Query: "${query}"

  Example output:
  {"name": "Joe Smith", "email": "joe.smith@example.com", "company": "IBM", "notes": "Met at a conference", "meta": ""}
  `.trim();

  try {
    const response = await axios.post(
      'https://api.cohere.ai/generate',
      {
        model: 'command-xlarge-nightly',
        prompt: prompt,
        max_tokens: 150,
        temperature: 0.3,
        stop_sequences: []
      },
      {
        headers: {
          'Authorization': `Bearer ${process.env.COHERE_API_KEY}`,
          'Content-Type': 'application/json'
        }
      }
    );

    const generatedText = response.data.text.trim();

    const contactDescription = JSON.parse(generatedText);
    console.log('Generated contact description:', contactDescription);
    return contactDescription;
  } catch (error) {
    console.error("Error generating contact description:", error.response?.data || error.message);
    return null;
  }
}