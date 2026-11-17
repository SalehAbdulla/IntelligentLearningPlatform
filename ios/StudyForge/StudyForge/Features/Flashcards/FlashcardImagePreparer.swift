import UIKit

enum FlashcardImagePreparer {

    static let maxDimension: CGFloat = 1_200
    static let maxBytes = 1_500_000
    static let quality: CGFloat = 0.75

    static func prepared(_ data: Data) -> Data? {
        guard let image = UIImage(data: data), image.size.width > 0, image.size.height > 0 else { return nil }
        let size = targetSize(for: image.size)
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let resized = UIGraphicsImageRenderer(size: size, format: format).image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
        guard let jpeg = resized.jpegData(compressionQuality: quality), jpeg.count <= maxBytes else { return nil }
        return jpeg
    }

    static func targetSize(for size: CGSize) -> CGSize {
        let longest = max(size.width, size.height)
        let scale = longest > maxDimension ? maxDimension / longest : 1
        return CGSize(width: (size.width * scale).rounded(), height: (size.height * scale).rounded())
    }
}
