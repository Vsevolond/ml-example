import CoreML
import SwiftUI
import PhotosUI


struct ContentView: View {
    @State
    @MainActor
    private var image: UIImage?
    
    @State
    private var selectedItem: PhotosPickerItem?
    
    @State
    @MainActor
    private var result: Result<String, ClassifierError> = .failure(ClassifierError.noResult)
    
    var body: some View {
        VStack {
            PhotosPicker(
                selection: $selectedItem,
                matching: .images,
                photoLibrary: .shared()
            ) {
                Text("Select a photo")
            }
            .onChange(of: selectedItem) { newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        image = UIImage(data: data)
                        classify(image: image)
                    }
                }
            }
            
            Image(
                uiImage: image ?? UIImage(named: "placeholder")!
            )
            .resizable()
            .scaledToFit()
            
            Text(result.description)
        }
        .padding()
    }
                
    @MainActor
    func classify(image: UIImage?) {
        result = .failure(ClassifierError.noResult)
        
        guard let cgImage = image?.cgImage else {
            result = .failure(ClassifierError.failedToReadImage)
            return
        }
        
        do {
            let className = try classify(cgImage: cgImage)
            guard let office = Office(rawValue: className) else {
                result = .failure(ClassifierError.failedToClassifyImage)
                return
            }
            result = .success(office.name)
        } catch {
            result = .failure(ClassifierError.failedToClassifyImage)
        }
    }
                
    func classify(cgImage: CGImage) throws -> String {
        let configuration = MLModelConfiguration()
        configuration.computeUnits = .all
        let model = try OfficeImageClassifier(configuration: configuration)
        let prediction = try model.prediction(input: .init(imageWith: cgImage))
        return prediction.classLabel
    }
}
                
enum ClassifierError: Error {
    case noResult
    case failedToReadImage
    case unexpectedResult
    case failedToClassifyImage
}
                
fileprivate enum Office: String {
    case vkSpbZinger = "VK_spb_zinger"
    case yandexMskNewOffice = "Yandex_msk_new_office"
    case yandexMskRedRose = "Yandex_msk_red_rose"
    case yandexSpbBenua = "Yandex_spb_benua"
    
    var name: String {
        switch self {
        case .vkSpbZinger:
            return "VK office in Saint-Petersburg at Zinger's House"
        case .yandexMskNewOffice:
            return "Yandex new office in Moscow"
        case .yandexMskRedRose:
            return "Yandex office in Moscow at Red Rose"
        case .yandexSpbBenua:
            return "Yandex office in Saint-Petersburg at Benua"
        }
    }
}
                
extension Result where Success == String, Failure == ClassifierError {
    var description: String {
        switch self {
        case let .success(text):
            return "I guess it's a \(text)"
        case let .failure(error):
            switch error {
            case .noResult:
                return ""
            default:
                return "Failure: \(error)"
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
