import Cocoa

protocol EngineAsking {
	static func ask(image: CGImage)
	static func describe(image: CGImage, system: String, prompt: String, completion: @escaping (String) -> Void)
}

enum Engines: Int {
	case gpt = 0, ollama, llamaCpp
}

func getEngine(for engine: Engines) -> EngineAsking.Type {
	switch engine {
	case .gpt:
		return GPT.self
	case .ollama:
		return Ollama.self
	case .llamaCpp:
		return LlamaCpp.self
	}
}

