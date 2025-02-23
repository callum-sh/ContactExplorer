//
//  TaskCard.swift
//  ContactExplorer
//
//  Created by callum on 2025-02-23.
//
import SwiftUI

struct TaskCardView: View {
    let taskItem: Task

    var body: some View {
        HStack(spacing: 16) {
            
            // date
            VStack {
                Text(formattedMonth(taskItem.date))
                    .font(.caption)
                
                Text(formattedDay(taskItem.date))
                    .font(.largeTitle)
                    .bold()
            }
            .frame(width: 50)

            // task
            Text(taskItem.task)
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(20)
        .frame(width: 362, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 30)
                .cornerRadius(30)
                .foregroundColor(Color(UIColor.secondarySystemBackground))
        )
    }


    private func formattedMonth(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        guard let date = formatter.date(from: dateString) else { return "N/A" }

        formatter.dateFormat = "MMM" // e.g., "Feb"
        return formatter.string(from: date)
    }

    private func formattedDay(_ dateString: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        guard let date = formatter.date(from: dateString) else { return "N/A" }

        formatter.dateFormat = "d" // e.g., "23"
        return formatter.string(from: date)
    }
}

#Preview {
    let sampleTask = Task(
        id: 1,
        date: "2025-02-23T07:02:17.107Z",
        task: "Meeting with Harvin to align on project details."
    )

    TaskCardView(taskItem: sampleTask)
}
