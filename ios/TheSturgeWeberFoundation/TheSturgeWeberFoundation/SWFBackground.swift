//
//  SWFBackground.swift
//  TheSturgeWeberFoundation
//
//  Created by Anannya Reddy Gade on 10/11/25.
//

import SwiftUI

/// Reusable background using the official group photo.
struct SWFBackground: View {
    var body: some View {
        Image("swf_bg")
            .resizable()
            .scaledToFill()
            .ignoresSafeArea()
            .overlay(
                Color.black.opacity(0.25) // improves text contrast
            )
    }
}
