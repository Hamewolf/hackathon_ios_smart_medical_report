//
//  ImagePicker.swift
//  VoxBible
//
//  Created by Mohamad on 20/10/25.
//


//import SwiftUI
//import UIKit
//
//struct ImagePicker: UIViewControllerRepresentable {
//    enum Source { case camera, library }
//    var source: Source
//    @Binding var imageData: Data?
//    @Environment(\.dismiss) private var dismiss
//
//    func makeUIViewController(context: Context) -> UIImagePickerController {
//        let picker = UIImagePickerController()
//        picker.delegate = context.coordinator
//        picker.sourceType = (source == .camera && UIImagePickerController.isSourceTypeAvailable(.camera)) ? .camera : .photoLibrary
//        picker.mediaTypes = ["public.image"]
//        return picker
//    }
//
//    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
//
//    func makeCoordinator() -> Coordinator { Coordinator(self) }
//
//    final class Coordinator: NSObject, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
//        let parent: ImagePicker
//        init(_ parent: ImagePicker) { self.parent = parent }
//        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { parent.dismiss() }
//        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
//            defer { parent.dismiss() }
//            guard let image = (info[.editedImage] ?? info[.originalImage]) as? UIImage else { return }
//            // Prefer PNG to preserve quality; we'll validate size later
//            if let pngData = image.pngData() {
//                parent.imageData = pngData
//            } else if let jpegData = image.jpegData(compressionQuality: 0.9) {
//                parent.imageData = jpegData
//            }
//        }
//    }
//}
