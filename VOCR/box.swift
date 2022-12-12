struct Box: Decodable {
	let x:Int
	let y:Int
	let w:Int
	let h:Int
	let l:String
}

let boxes:[Box] = try! JSONDecoder()Box.decode(.self, from: json)
