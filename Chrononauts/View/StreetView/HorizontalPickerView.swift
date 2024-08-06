//
//  HorizontalView.swift
//  Chrononauts
//
//  Created by FredyCamas on 7/26/24.
//

import SwiftUI

struct HorizontalPickerView: View {
    var images: [PanoImages]
    var onImageSelected: (Int?) -> Void
    
    @State private var selectedIndex: Int?
    @State private var scrollViewProxy: ScrollViewProxy?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            ScrollViewReader { proxy in
                HStack(spacing: 15) {
                    ForEach(images.indices, id: \.self) { index in
                        VStack {
                            Text(images[index].year)
                                .font(.caption)
                                .foregroundColor(.white)
                            
                            Image(uiImage: UIImage(named: "\(images[index].name)")!)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100, height: 100)
                                .clipShape(Rectangle())
                                .overlay(
                                    ZStack {
                                        if selectedIndex == index {
                                            Rectangle()
                                                .stroke(Color.green, lineWidth: 3)
                                                .frame(width: 100, height: 50)
                                               
                                            Rectangle()
                                                .fill(Color.green)
                                                .frame(width: 2, height: 30)
                                                .offset(y: -40)
                                        }
                                    }
                                )
                                .onTapGesture {
                                    if selectedIndex == index {
                                        // selectedIndex = nil
                                        // onImageSelected(nil) // Notify that no image is selected
                                    } else {
                                        selectedIndex = index
                                        onImageSelected(selectedIndex)
                                    }
                                    scrollToSelectedIndex(proxy: proxy)
                                }
                                .id(index)
                        }
                    }
                }
                .padding()
                .onAppear {
                    scrollViewProxy = proxy
                    scrollToSelectedIndex(proxy: proxy)
                    selectedIndex = 0
                }
                .onChange(of: selectedIndex) { _ in
                    if let proxy = scrollViewProxy {
                        scrollToSelectedIndex(proxy: proxy)
                    }
                }
            }
        }
        .frame(height: 60) // Adjust height if necessary
        .background(Color.black)
        .edgesIgnoringSafeArea(.all)
    }
    
    private func scrollToSelectedIndex(proxy: ScrollViewProxy) {
        DispatchQueue.main.async {
            if let index = selectedIndex {
                proxy.scrollTo(index, anchor: .center)
            }
        }
    }
}
