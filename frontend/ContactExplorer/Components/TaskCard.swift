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
        VStack(alignment: .leading, spacing: 15) {
            
            // Day
            Text(formattedDate(taskItem.date))
                .font(.custom("HelveticaNeue-Light", size: 17))
                .foregroundColor(.secondary)                

            // Task Description
            Text(taskItem.task)
                .font(.body)
                .foregroundColor(.primary)
                .font(.custom("NewYork-Regular", size: 17)) // todo: font not working
        }
        .padding(30)
        .frame(width: 362, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 30)
                .cornerRadius(30)
                .foregroundColor(Color(UIColor.secondarySystemBackground))
        )
    }
    
    private func formattedDate(_ dateString: String) -> String {
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        // String → Date
        if let date = isoFormatter.date(from: dateString) {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            return formatter.string(from: date)
        } else {
            return "N/A"
        }
    }
}

#Preview {
    TasksView()
}
