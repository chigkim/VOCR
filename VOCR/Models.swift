import Cocoa

protocol ModelAsking {
	static func ask(image: CGImage)
	static func describe(image: CGImage, system: String, prompt: String, completion: @escaping (String) -> Void)
}

enum Models: Int {
	case gpt = 0, ollama, llamaCpp
}

func getModel(for model: Models) -> ModelAsking.Type {
	switch model {
	case .gpt:
		return GPT.self
	case .ollama:
		return Ollama.self
	case .llamaCpp:
		return LlamaCpp.self
	}
}

