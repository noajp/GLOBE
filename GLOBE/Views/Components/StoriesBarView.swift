//======================================================================
// MARK: - StoriesBarView.swift
// Purpose: Horizontal scrollable stories bar component
// Path: GLOBE/Views/Components/StoriesBarView.swift
//======================================================================

import SwiftUI

struct StoriesBarView: View {
    let stories: [Story]
    @Binding var selectedStory: Story?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                // フォロー中のユーザーのストーリー
                ForEach(stories.filter { !$0.isExpired }) { story in
                    Button(action: {
                        selectedStory = story
                    }) {
                        VStack(spacing: 6) {
                            // User avatar
                            Circle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: 60, height: 60)
                                .overlay(
                                    Text(story.userName.prefix(1))
                                        .font(.title2)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                )
                                .overlay(
                                    Circle()
                                        .stroke(Color.blue, lineWidth: 2)
                                )

                            Text(story.userName)
                                .font(.caption)
                                .foregroundColor(.white)
                                .lineLimit(1)
                                .frame(width: 60)
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 20)
        }
        .frame(height: 100)
        .background(MinimalDesign.Colors.background)
    }
}

#Preview {
    StoriesBarView(
        stories: Story.mockStories,
        selectedStory: .constant(nil)
    )
    .background(.black)
}