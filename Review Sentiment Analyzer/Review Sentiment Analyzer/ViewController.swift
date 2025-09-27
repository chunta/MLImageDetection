import UIKit
import NaturalLanguage

class ViewController: UIViewController, UITextViewDelegate {
    
    @IBOutlet var textView: UITextView!
    @IBOutlet var clearButton: UIButton!
    @IBOutlet var statusText: UILabel!
        
    private lazy var sentimentClassifier: NLModel? = {
        let model = try? NLModel (mlModel: ReviewClassifier().model)
        return model
    }()
    override func viewDidLoad() {
        super.viewDidLoad()
        textView.delegate = self
        toggleClearButtonEnable()
    }
    
    @IBAction func onClearTest(_ sender: Any)
    {
        textView.text = ""
        setStatusText("--")
    }
    
    // UITextViewDelegate
    func textViewDidChange(_ textView: UITextView) {
        toggleClearButtonEnable()
        setStatusText("--")
        if textView.text.count > 0 {
            if let label = sentimentClassifier?.predictedLabel(for: textView.text) as? String {
                print("lable \(label)")
                switch label {
                case "positive":
                    setStatusText(":)")
                    break
                case "negative":
                    setStatusText(":(")
                    break
                default:
                    setStatusText("--")
                    break
                }
            }
        }
    }
    
    private func setStatusText(_ text: String)
    {
        statusText.text = text
    }
    
    private func toggleClearButtonEnable()
    {
     //   clearButton.isEnabled = !textView.text.isEmpty
    }
}
