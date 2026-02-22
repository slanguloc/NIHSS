//
//  PatientResponseService.swift
//  NIHSS Stroke Scale — Capture and translate patient speech (item 1b).
//

import AVFoundation
import Speech
import SwiftUI

/// Handles microphone capture, speech-to-text, and translation for patient responses.
final class PatientResponseService: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var recordingQuestionIndex: Int? = nil
    @Published var recordingKey: String? = nil
    @Published var transcribedText = ""
    @Published var translatedText = ""
    @Published var response1Transcribed = ""
    @Published var response1Translated = ""
    @Published var response2Transcribed = ""
    @Published var response2Translated = ""
    @Published var response9_1Transcribed = ""
    @Published var response9_1Translated = ""
    @Published var response9_3Transcribed = ""
    @Published var response9_3Translated = ""
    @Published var response8Transcribed = ""
    @Published var response8Translated = ""
    @Published var response11Transcribed = ""
    @Published var response11Translated = ""
    @Published var errorMessage: String?
    @Published var authorizationStatus: SFSpeechRecognizerAuthorizationStatus = .notDetermined

    private var audioEngine: AVAudioEngine?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    /// Recognizer for current recording session (Spanish or Haitian Creole).
    private var currentRecognizer: SFSpeechRecognizer?
    /// Language for the active recording; used when translating to English.
    private var recordingLanguage: AppLanguage = .spanish

    /// Returns a speech recognizer for the given patient language, or Spanish fallback.
    private func speechRecognizer(for language: AppLanguage) -> SFSpeechRecognizer? {
        switch language {
        case .spanish:
            return SFSpeechRecognizer(locale: Locale(identifier: "es-ES"))
                ?? SFSpeechRecognizer(locale: Locale(identifier: "es-MX"))
                ?? SFSpeechRecognizer(locale: Locale(identifier: "es"))
        case .haitianCreole:
            return SFSpeechRecognizer(locale: Locale(identifier: "ht-HT"))
                ?? SFSpeechRecognizer(locale: Locale(identifier: "ht"))
                ?? SFSpeechRecognizer(locale: Locale(identifier: "fr-HT"))
        }
    }

    override init() {
        super.init()
    }

    /// Request microphone and speech recognition permissions.
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { [weak self] status in
            DispatchQueue.main.async {
                self?.authorizationStatus = status
                switch status {
                case .authorized:
                    completion(true)
                case .denied:
                    self?.errorMessage = "Speech recognition denied. Enable in Settings."
                    completion(false)
                case .restricted:
                    self?.errorMessage = "Speech recognition restricted."
                    completion(false)
                case .notDetermined:
                    self?.errorMessage = "Speech recognition not determined."
                    completion(false)
                @unknown default:
                    completion(false)
                }
            }
        }
    }

    /// Start recording for item 1b (questionIndex 0 = month, 1 = age).
    func startRecording(questionIndex: Int, language: AppLanguage = .spanish) {
        startRecording(key: "1b-\(questionIndex)", language: language)
    }

    /// Start recording for a key: "1b-0", "1b-1", "9-0" (subsection 1), "9-2" (subsection 3). Uses the given language for recognition and translation.
    func startRecording(key: String, language: AppLanguage = .spanish) {
        var recognizer = speechRecognizer(for: language)
        if recognizer == nil || recognizer?.isAvailable == false {
            recognizer = speechRecognizer(for: .spanish)
            recordingLanguage = .spanish
        } else {
            recordingLanguage = language
        }
        guard let speechRecognizer = recognizer, speechRecognizer.isAvailable else {
            errorMessage = "Speech recognition not available for this language."
            return
        }
        currentRecognizer = speechRecognizer

        errorMessage = nil
        transcribedText = ""
        translatedText = ""
        if key.hasPrefix("1b-"), let idx = Int(key.suffix(1)) {
            recordingQuestionIndex = idx
            recordingKey = nil
        } else {
            recordingQuestionIndex = nil
            recordingKey = key
        }
        recognitionTask?.cancel()
        recognitionTask = nil

        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            errorMessage = "Audio session error: \(error.localizedDescription)"
            return
        }

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else { return }
        recognitionRequest.shouldReportPartialResults = true
        recognitionRequest.requiresOnDeviceRecognition = false

        audioEngine = AVAudioEngine()
        guard let audioEngine = audioEngine else { return }
        let inputNode = audioEngine.inputNode

        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            errorMessage = "Could not start audio engine: \(error.localizedDescription)"
            return
        }
        isRecording = true

        recognitionTask = currentRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if let result = result {
                    self.transcribedText = result.bestTranscription.formattedString
                    if result.isFinal, !result.bestTranscription.formattedString.isEmpty {
                        let translated = self.translateToEnglish(result.bestTranscription.formattedString, from: self.recordingLanguage)
                        self.saveResponse(transcribed: result.bestTranscription.formattedString, translated: translated)
                    }
                }
                if error != nil || (result?.isFinal == true) {
                    self.stopRecording()
                }
            }
        }
    }

    /// Stop recording and finalize transcription.
    func stopRecording() {
        audioEngine?.stop()
        audioEngine?.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest = nil
        audioEngine = nil
        isRecording = false
        if !transcribedText.isEmpty {
            let translated = translateToEnglish(transcribedText, from: recordingLanguage)
            saveResponse(transcribed: transcribedText, translated: translated)
        }
        recordingQuestionIndex = nil
        recordingKey = nil
        currentRecognizer = nil
    }

    private func saveResponse(transcribed: String, translated: String) {
        if let idx = recordingQuestionIndex {
            if idx == 0 {
                response1Transcribed = transcribed
                response1Translated = translated
            } else if idx == 1 {
                response2Transcribed = transcribed
                response2Translated = translated
            }
        } else if let key = recordingKey {
            if key == "9-0" {
                response9_1Transcribed = transcribed
                response9_1Translated = translated
            } else if key == "9-2" {
                response9_3Transcribed = transcribed
                response9_3Translated = translated
            } else if key == "8" {
                response8Transcribed = transcribed
                response8Translated = translated
            } else if key == "11" {
                response11Transcribed = transcribed
                response11Translated = translated
            }
        }
    }

    func responseForItem9(subsectionIndex: Int) -> (transcribed: String, translated: String) {
        if subsectionIndex == 0 {
            return (response9_1Transcribed, response9_1Translated)
        }
        if subsectionIndex == 2 {
            return (response9_3Transcribed, response9_3Translated)
        }
        return ("", "")
    }

    func isRecordingItem9(subsectionIndex: Int) -> Bool {
        guard let key = recordingKey else { return false }
        return (subsectionIndex == 0 && key == "9-0") || (subsectionIndex == 2 && key == "9-2")
    }

    func responseForItem8() -> (transcribed: String, translated: String) {
        (response8Transcribed, response8Translated)
    }

    func isRecordingItem8() -> Bool {
        recordingKey == "8"
    }

    func responseForItem11() -> (transcribed: String, translated: String) {
        (response11Transcribed, response11Translated)
    }

    func isRecordingItem11() -> Bool {
        recordingKey == "11"
    }

    func reset() {
        transcribedText = ""
        translatedText = ""
        response1Transcribed = ""
        response1Translated = ""
        response2Transcribed = ""
        response2Translated = ""
        response9_1Transcribed = ""
        response9_1Translated = ""
        response9_3Transcribed = ""
        response9_3Translated = ""
        response8Transcribed = ""
        response8Translated = ""
        response11Transcribed = ""
        response11Translated = ""
        errorMessage = nil
    }

    /// Translate patient speech to English (Spanish or Haitian Creole).
    private func translateToEnglish(_ text: String, from language: AppLanguage) -> String {
        switch language {
        case .spanish: return translateSpanishToEnglish(text)
        case .haitianCreole: return translateCreoleToEnglish(text)
        }
    }

    /// Spanish → English translation (word-by-word + phrases) for LOC and item 9.
    private func translateSpanishToEnglish(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return text }

        var result = trimmed.lowercased()

        // Multi-word phrases first (longer matches)
        let phrases: [(String, String)] = [
            ("sesenta y cinco", "65"), ("sesenta y uno", "61"), ("setenta y cinco", "75"),
            ("ochenta y cinco", "85"), ("cincuenta y cinco", "55"),
            ("no sé", "I don't know"), ("no recuerdo", "I don't remember"),
            ("caja fuerte", "safe"), ("cortadora de césped", "lawn mower"), ("cortadora de cesped", "lawn mower"),
            ("un hombre cortando el pasto", "a man cutting the grass"), ("un hombre cortando el césped", "a man cutting the grass"), ("un hombre cortando el cesped", "a man cutting the grass"),
            ("una mujer cortando el pasto", "a woman cutting the grass"), ("una mujer cortando el césped", "a woman cutting the grass"),
            ("cortando el pasto", "cutting the grass"), ("cortando el césped", "cutting the grass"), ("cortando el cesped", "cutting the grass"), ("cortando la hierba", "cutting the grass"),
            ("segando el pasto", "mowing the grass"), ("segando el césped", "mowing the grass"), ("segando el cesped", "mowing the grass"),
            ("recogiendo frutas", "picking fruits"), ("recogiendo fruta", "picking fruit"), ("recogiendo flores", "picking flowers"),
            ("cogiendo frutas", "picking fruits"), ("cogiendo fruta", "picking fruit"),
            ("los dos lados", "both sides"), ("igual en los dos lados", "same on both sides"), ("el mismo", "the same"), ("la misma", "the same"),
            ("en ambos lados", "on both sides"), ("por ambos lados", "on both sides"), ("los dos", "both"), ("las dos", "both"), ("uno y otro", "both"), ("una y otra", "both"), ("en los dos", "on both"), ("en las dos", "on both"),
        ]
        for (es, en) in phrases {
            result = result.replacingOccurrences(of: es, with: en)
        }

        // Single-word dictionary: months, numbers, objects, common words
        let words: [String: String] = [
            "enero": "January", "febrero": "February", "marzo": "March", "abril": "April",
            "mayo": "May", "junio": "June", "julio": "July", "agosto": "August",
            "septiembre": "September", "octubre": "October", "noviembre": "November", "diciembre": "December",
            "cero": "0", "uno": "1", "dos": "2", "tres": "3", "cuatro": "4", "cinco": "5",
            "seis": "6", "siete": "7", "ocho": "8", "nueve": "9", "diez": "10",
            "once": "11", "doce": "12", "trece": "13", "catorce": "14", "quince": "15",
            "dieciséis": "16", "diecisiete": "17", "dieciocho": "18", "diecinueve": "19",
            "veinte": "20", "treinta": "30", "cuarenta": "40", "cincuenta": "50",
            "sesenta": "60", "setenta": "70", "ochenta": "80", "noventa": "90", "cien": "100",
            "veintiuno": "21", "veintidós": "22", "veintitrés": "23", "veinticuatro": "24",
            "veinticinco": "25", "veintiséis": "26", "veintisiete": "27", "veintiocho": "28", "veintinueve": "29",
            "caballo": "horse", "caballos": "horses", "potro": "horse", "potros": "horses", "yegua": "horse", "yeguas": "horses", "corcel": "horse",
            "pelota": "ball", "pelotas": "balls", "bola": "ball", "bolas": "balls", "balón": "ball", "balon": "ball", "balones": "balls", "esfera": "ball",
            "árbol": "tree", "arbol": "tree", "árboles": "trees", "arboles": "trees",
            "silla": "chair", "sillas": "chairs", "asiento": "chair", "asientos": "chairs", "sillón": "chair", "sillon": "chair", "sillones": "chairs",
            "sofá": "couch", "sofa": "couch", "sofás": "couches", "sofas": "couches", "canapé": "couch", "canape": "couch", "diván": "couch", "divan": "couch", "divanes": "couches",
            "candado": "lock", "candados": "locks", "cerradura": "lock", "cerraduras": "locks", "tranca": "lock",
            "seguro": "safe", "seguros": "safes",
            "coche": "car", "coches": "cars", "carro": "car", "carros": "cars", "auto": "car", "autos": "cars", "automóvil": "car", "automovil": "car", "automóviles": "cars", "vehículo": "car", "vehiculo": "car", "vehículos": "cars", "vehiculos": "cars",
            "reloj": "watch", "relojes": "watches", "lápiz": "pencil", "lapiz": "pencil", "lápices": "pencils",
            "lapicero": "pencil", "lapiceros": "pencils", "bolígrafo": "pen", "pluma": "pen",
            "veo": "I see", "ves": "you see", "vemos": "we see", "es": "is", "está": "is", "estan": "are",
            "están": "are", "estamos": "we are", "hay": "there is", "un": "a", "una": "a","el": "the", "la": "the", "los": "the", "las": "the",
            "hombre": "man", "hombres": "men", "mujer": "woman", "mujeres": "women", "persona": "person", "personas": "people",
            "casa": "house", "casas": "houses", "mesa": "table", "mesas": "tables",
            "sol": "sun", "soleado": "sunny", "agua": "water",
            "cielo": "sky", "cielos": "sky", "firmamento": "sky",
            "camino": "road", "caminos": "roads", "carretera": "road", "carreteras": "roads", "calle": "road", "calles": "roads", "callejón": "road", "callejon": "road", "callejones": "roads", "vía": "road", "via": "road", "vías": "roads", "vias": "roads", "ruta": "road", "rutas": "roads", "avenida": "road", "avenidas": "roads", "pista": "road", "pistas": "roads", "sendero": "road", "senderos": "roads", "calzada": "road",
            "nube": "cloud", "nubes": "clouds", "nubarrón": "cloud", "nubarron": "cloud", "nubarrones": "clouds",
            "pájaro": "bird", "pajaro": "bird", "pájaros": "birds", "pajaros": "birds", "ave": "bird", "aves": "birds", "pájaritos": "birds", "pajaritos": "birds",
            "fruta": "fruit", "frutas": "fruits", "fruto": "fruit", "frutos": "fruits", "manzana": "apple", "manzanas": "apples", "naranja": "orange", "naranjas": "oranges", "plátano": "banana", "platano": "banana", "plátanos": "bananas", "platanos": "bananas", "banana": "banana", "bananas": "bananas", "uvas": "grapes", "sandía": "watermelon", "sandia": "watermelon", "sandías": "watermelons", "pera": "pear", "peras": "pears", "melón": "melon", "melon": "melon", "melones": "melons", "fresa": "strawberry", "fresas": "strawberries", "frutilla": "strawberry", "frutillas": "strawberries", "cereza": "cherry", "cerezas": "cherries", "durazno": "peach", "duraznos": "peaches", "mango": "mango", "mangos": "mangoes", "piña": "pineapple", "pina": "pineapple", "piñas": "pineapples", "pinas": "pineapples", "limón": "lemon", "limon": "lemon", "limones": "lemons",
            "escalera": "stairs", "escaleras": "stairs", "escalón": "step", "escalon": "step", "escalones": "steps", "gradas": "stairs", "peldaño": "step", "peldaños": "steps",
            "cortacésped": "lawn mower", "cortacesped": "lawn mower", "cortacéspedes": "lawn mowers", "podadora": "lawn mower", "podadoras": "lawn mowers", "segadora": "lawn mower", "segadoras": "lawn mowers",
            "césped": "grass", "cesped": "grass", "pasto": "grass", "hierba": "grass", "hierbas": "grass", "grama": "grass", "gramilla": "grass",
            "cortar": "cut", "cortando": "cutting", "corta": "cuts", "corto": "I cut", "cortas": "you cut", "cortamos": "we cut", "cortan": "they cut", "cortado": "cut", "cortada": "cut", "cortados": "cut", "cortadas": "cut", "corte": "cut", "cortes": "cuts",
            "segar": "mow", "segando": "mowing", "siega": "mows", "segado": "mowed", "segada": "mowed", "segados": "mowed",
            "recoger": "pick", "recogiendo": "picking", "recoge": "picks", "recojo": "I pick", "recoges": "you pick", "recogen": "they pick", "recogido": "picked", "recogida": "picked", "recogidos": "picked", "recogidas": "picked",
            "coger": "pick", "cogiendo": "picking", "coge": "picks", "cojo": "I pick", "cogen": "they pick", "cogido": "picked", "cogida": "picked",
            "perro": "dog", "perros": "dogs", "gato": "cat", "gatos": "cats", "niño": "boy", "niña": "girl",
            "niños": "children", "niñas": "girls", "familia": "family", "madre": "mother", "padre": "father",
            "cabeza": "head", "mano": "hand", "manos": "hands", "pie": "foot", "pies": "feet",
            "ojo": "eye", "ojos": "eyes", "boca": "mouth", "nariz": "nose",
            "grande": "big", "pequeño": "small", "pequeña": "small", "rojo": "red", "azul": "blue",
            "blanco": "white", "negro": "black", "verde": "green", "amarillo": "yellow",
            "y": "and", "con": "with", "en": "in", "de": "of", "del": "of the", "que": "that", "por": "by",
            "para": "for", "como": "like", "muy": "very", "más": "more", "esto": "this", "esta": "this",
            "eso": "that", "aquí": "here", "allí": "there","tengo":"I have", "año":"year", "años":"years old",
            "igual": "same", "lado": "side", "lados": "sides", "derecha": "right", "izquierda": "left", "siento": "I feel", "siente": "feels", "dolor": "pain", "toco": "I touch", "toca": "touches", "piel": "skin",
            "ambos": "both", "ambas": "both",
        ]

        let tokens = result.split(separator: " ").map(String.init)
        var translated: [String] = []
        for token in tokens {
            let cleaned = token.lowercased().trimmingCharacters(in: .punctuationCharacters)
            let normalized = cleaned.folding(options: .diacriticInsensitive, locale: nil)
            let en = words[cleaned] ?? words[normalized]
            if let en = en {
                let suffix = String(token.dropFirst(cleaned.count))
                translated.append(en + suffix)
            } else {
                translated.append(token)
            }
        }
        result = translated.joined(separator: " ")
        if result.isEmpty { return text }
        return result.prefix(1).uppercased() + result.dropFirst()
    }

    /// Haitian Creole → English translation (word-by-word + phrases) for LOC and item 9.
    private func translateCreoleToEnglish(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return text }

        var result = trimmed.lowercased()

        // Multi-word phrases first
        let phrases: [(String, String)] = [
            ("mwen pa konnen", "I don't know"), ("mwen pa sonje", "I don't remember"),
            ("pa konnen", "don't know"), ("pa sonje", "don't remember"),
            ("mwen gen", "I have"),
            ("tou de bò", "both sides"), ("menm bagay", "same thing"), ("menm sou tou de bò", "same on both sides"),
            ("tou de", "both"), ("toulede", "both"), ("toule de", "both"), ("tou le de", "both"), ("tout de", "both"), ("sou tou de bò", "on both sides"), ("nan tou de bò", "on both sides"),
        ]
        for (ht, en) in phrases {
            result = result.replacingOccurrences(of: ht, with: en)
        }

        // Creole months, numbers, and common words
        let words: [String: String] = [
            "janvye": "January", "fevriye": "February", "mas": "March", "avril": "April",
            "me": "May", "jen": "June", "jiyè": "July", "out": "August",
            "septanm": "September", "oktòb": "October", "novanm": "November", "desanm": "December",
            "zero": "0", "en": "1", "de": "2", "twa": "3", "kat": "4", "senk": "5",
            "sis": "6", "sèt": "7", "uit": "8", "nèf": "9", "dis": "10",
            "onz": "11", "douz": "12", "trèz": "13", "katoz": "14", "kenz": "15",
            "sèz": "16", "disèt": "17", "dizuit": "18", "diznèf": "19",
            "ven": "20", "trant": "30", "karant": "40", "senkant": "50",
            "swasann": "60", "swasantdis": "70", "katreven": "80", "katrevenndis": "90", "san": "100",
            "mont": "watch", "mont yo": "watches", "kreyon": "pencil", "kreyon yo": "pencils",
            "cheval": "horse", "chwal": "horse", "boul": "ball", "boul yo": "balls",
            "pye bwa": "tree", "pyebwa": "tree", "chèz": "chair", "chèz yo": "chairs",
            "kanape": "couch", "sofá": "couch", "kadna": "lock", "kadna yo": "locks",
            "kòf": "safe", "machin": "car", "machin yo": "cars", "oto": "car",
            "kay": "house", "tab": "table", "sole": "sun", "dlo": "water",
            "syèl": "sky", "wout": "road", "niyaj": "cloud", "zwazo": "bird", "zwazo yo": "birds",
            "fwi": "fruit", "fwi yo": "fruits", "pom": "apple", "zoranj": "orange", "bannann": "banana",
            "eskalye": "stairs", "gazon": "grass", "tè": "grass", "zèb": "grass",
            "moun": "person", "nonm": "man", "fi": "woman", "fanmi": "family",
            "mwen wè": "I see", "wè": "see", "se": "is", "gen": "there is", "yon": "a", "la": "the",
            "ak": "and", "avèk": "with", "nan": "in", "pou": "for", "trè": "very",
            "gran": "big", "piti": "small", "wouj": "red", "ble": "blue", "blan": "white", "nwa": "black", "vèt": "green", "jòn": "yellow",
            "ane": "year", "lane": "years", "gen": "there is", "mwen": "I",
            "menm": "same", "bò": "side", "doulè": "pain", "santi": "feel", "manyen": "touch", "po": "skin",
            "toulede": "both", "toule": "both", "tout": "all",
        ]

        let tokens = result.split(separator: " ").map(String.init)
        var translated: [String] = []
        for token in tokens {
            let cleaned = token.lowercased().trimmingCharacters(in: .punctuationCharacters)
            let normalized = cleaned.folding(options: .diacriticInsensitive, locale: nil)
            let en = words[cleaned] ?? words[normalized]
            if let en = en {
                let suffix = String(token.dropFirst(cleaned.count))
                translated.append(en + suffix)
            } else {
                translated.append(token)
            }
        }
        result = translated.joined(separator: " ")
        if result.isEmpty { return text }
        return result.prefix(1).uppercased() + result.dropFirst()
    }
}
