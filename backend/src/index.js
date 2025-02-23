const express = require('express');
const axios = require('axios');

// ensure db is connected 
const pool = require('./db');
require('dotenv').config();

const app = express();
const port = process.env.PORT || 3000;

app.use(express.json());

app.get('/', (req, res) => {
    res.send("Hello from Express!"); 
});


/**
 * Embed a contact in the database 
 */
app.post('/embedContact', async (req, res) => {
    const { name, email, company, notes, meta } = req.body;

    // TODO: decide whether phone number / locational lookup is required 
    const textForEmbedding = `Name: ${name}. Email: ${email}. Company: ${company}. Notes: ${notes}. Additional Info: ${meta || ''}`;
    // TODO: check not already exist 

    try {
        // create embedding using cohere for given contact 
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

        // return the embedded contact
        res.json(result.rows[0]);

    } catch (error) {
        console.error('Error embedding contact:', error.response?.data || error);
        res.status(500).json({ error: 'Error embedding contact' });
    }
});

/**
 * Query embedding space for contact best matching query 
 */
app.post('/queryContact', async (req, res) => {
    const { query } = req.body;

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
    
        // TODO: call llm to gen better summary 
        const prompt = `Given the following contact details, generate a spoken summary that highlights key information:
            Name: ${bestMatch.name}
            Company: ${bestMatch.company}
            Notes: ${bestMatch.notes}

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
          contact: bestMatch,
          summary,
          similarity: highestSimilarity
        });

      } catch (error) {
        console.error('Error querying contact:', error.response?.data || error);
        res.status(500).json({ error: 'Error querying contact' });
      }
});


// TODO: save recent voice memos 

// Start the server
app.listen(port, () => {
  console.log(`Server running on port ${port}`);
});




// HELPERS

const cosineSimilarity = (vecA, vecB) => {
    const dotProduct = vecA.reduce((acc, val, idx) => acc + val * vecB[idx], 0);
    const normA = Math.sqrt(vecA.reduce((acc, val) => acc + val * val, 0));
    const normB = Math.sqrt(vecB.reduce((acc, val) => acc + val * val, 0));
    return dotProduct / (normA * normB);
};