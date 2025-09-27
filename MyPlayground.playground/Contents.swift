import Cocoa
import CreateML

var greeting = "Hello, playground"
guard let trainDataFileURL
= Bundle.main.url(forResource: "amazon-reviews", withExtension: "json"), let testDataFileURL
        = Bundle.main.url(forResource: "testing-reviews", withExtension: "json") else {
    fatalError("File Not Found")
}

do {
    let trainDataTable = try MLDataTable(contentsOf: trainDataFileURL)
    let testDataTable = try MLDataTable(contentsOf: testDataFileURL)
    let state = "\(trainDataTable.size) \(testDataTable.size)"
    print(state)
    
    let sentimentClassifier = try MLTextClassifier(trainingData: trainDataTable, textColumn: "text", labelColumn: "label")
    
    let trainingAccuracy = (1.0 - sentimentClassifier.trainingMetrics.classificationError) * 100
    print("training accuracy: \(trainingAccuracy)")
    
    let modelFileUrl = URL(fileURLWithPath: "/Users/rex/review.mlmodel")
    let metaData = MLModelMetadata(author: "rex", shortDescription: "123", version: "1.0")
    try sentimentClassifier.write(to: modelFileUrl, metadata: metaData)
    
} catch {
    print(error)
}

