import Foundation

class PasswordAPIService: ObservableObject {
    @Published var isLoading = false
    @Published var statusMessage = ""
    @Published var lastFetchTime: Date?
    @Published var isMonitoring = false
    @Published var userID = "18077"
    
    private var timer: Timer?
    private let baseURL = "https://11z.co/_w/"
    private let endpoint = "/selection"
    private var lastKnownValue: String? = nil
    
    var apiURL: String {
        return baseURL + userID + endpoint
    }
    
    func fetchPasswordFromAPI(completion: @escaping (String?) -> Void) {
        isLoading = true
        statusMessage = "Fetching password from API..."
        
        guard let url = URL(string: apiURL) else {
            statusMessage = "Invalid URL"
            isLoading = false
            completion(nil)
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.statusMessage = "Error: \(error.localizedDescription)"
                    completion(nil)
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    self?.statusMessage = "Invalid response"
                    completion(nil)
                    return
                }
                
                guard httpResponse.statusCode == 200 else {
                    self?.statusMessage = "HTTP Error: \(httpResponse.statusCode)"
                    completion(nil)
                    return
                }
                
                guard let data = data else {
                    self?.statusMessage = "No data received"
                    completion(nil)
                    return
                }
                
                // Пытаемся получить текст из ответа
                if let responseString = String(data: data, encoding: .utf8) {
                    let trimmedString = responseString.trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    // Пытаемся парсить JSON и извлечь value
                    if let jsonData = trimmedString.data(using: .utf8),
                       let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                       let value = json["value"] as? String {
                        
                        // Валидация пароля из value
                        if self?.isValidPassword(value) == true {
                            self?.statusMessage = "Password fetched successfully"
                            self?.lastFetchTime = Date()
                            completion(value)
                        } else {
                            self?.statusMessage = "Invalid password format in value"
                            completion(nil)
                        }
                    } else {
                        // Если не JSON, пробуем использовать как есть
                        if self?.isValidPassword(trimmedString) == true {
                            self?.statusMessage = "Password fetched successfully"
                            self?.lastFetchTime = Date()
                            completion(trimmedString)
                        } else {
                            self?.statusMessage = "Invalid password format received"
                            completion(nil)
                        }
                    }
                } else {
                    self?.statusMessage = "Could not decode response"
                    completion(nil)
                }
            }
        }
        
        task.resume()
    }
    
    func startMonitoring() {
        guard !isMonitoring else { return }
        
        isMonitoring = true
        statusMessage = "Started monitoring API (waiting for changes)..."
        
        // При первом запуске получаем текущее значение, но не обновляем пароль
        fetchPasswordFromAPI { [weak self] password in
            if let password = password {
                self?.lastKnownValue = password
                self?.statusMessage = "Monitoring started - current value: \(password)"
            }
        }
        
        // Проверяем каждые 5 секунд
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.checkForUpdates()
        }
    }
    
    func stopMonitoring() {
        isMonitoring = false
        timer?.invalidate()
        timer = nil
        lastKnownValue = nil
        statusMessage = "Stopped monitoring"
    }
    
    private func checkForUpdates() {
        fetchPasswordFromAPI { [weak self] password in
            if let password = password {
                // Проверяем, изменилось ли значение
                if self?.lastKnownValue != password {
                    // Обновляем только при изменении
                    UserDefaults.standard.set(password, forKey: "userPassword")
                    
                    // Автоматически изменяем длину пароля в зависимости от полученного пароля
                    let passwordLength = password.count
                    UserDefaults.standard.set(passwordLength, forKey: "passLength")
                    
                    self?.statusMessage = "Password updated from API (value changed from \(self?.lastKnownValue ?? "nil") to \(password))"
                    self?.lastFetchTime = Date()
                    self?.lastKnownValue = password
                    
                    // Уведомляем об изменении
                    NotificationCenter.default.post(name: .passwordUpdatedFromAPI, object: password)
                } else {
                    // Значение не изменилось
                    self?.statusMessage = "Monitoring - no changes in API value"
                }
            }
        }
    }
    
    private func isValidPassword(_ password: String) -> Bool {
        // Пароль должен быть 4-6 цифр
        return password.count >= 4 && 
               password.count <= 6 && 
               password.allSatisfy { $0.isNumber }
    }
    
    func fetchValue() {
        fetchPasswordFromAPI { [weak self] password in
            if let password = password {
                // Автоматически обновляем пароль в UserDefaults
                UserDefaults.standard.set(password, forKey: "userPassword")
                self?.statusMessage = "Password fetched successfully"
                self?.lastFetchTime = Date()
                
                // Уведомляем об изменении
                NotificationCenter.default.post(name: .passwordUpdatedFromAPI, object: password)
            }
        }
    }
    
    func instantCatch(completion: @escaping (String?) -> Void) {
        isLoading = true
        statusMessage = "Instant catching password from API..."
        
        guard let url = URL(string: apiURL) else {
            statusMessage = "Invalid URL"
            isLoading = false
            completion(nil)
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.statusMessage = "Error: \(error.localizedDescription)"
                    completion(nil)
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    self?.statusMessage = "Invalid response"
                    completion(nil)
                    return
                }
                
                guard httpResponse.statusCode == 200 else {
                    self?.statusMessage = "HTTP Error: \(httpResponse.statusCode)"
                    completion(nil)
                    return
                }
                
                guard let data = data else {
                    self?.statusMessage = "No data received"
                    completion(nil)
                    return
                }
                
                // Пытаемся получить текст из ответа
                if let responseString = String(data: data, encoding: .utf8) {
                    let trimmedString = responseString.trimmingCharacters(in: .whitespacesAndNewlines)
                    
                    // Пытаемся парсить JSON и извлечь value
                    if let jsonData = trimmedString.data(using: .utf8),
                       let json = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
                       let value = json["value"] as? String {
                        
                        // Валидация пароля из value
                        if self?.isValidPassword(value) == true {
                            self?.statusMessage = "Password caught successfully"
                            self?.lastFetchTime = Date()
                            
                            // Автоматически изменяем длину пароля в зависимости от полученного пароля
                            let passwordLength = value.count
                            UserDefaults.standard.set(passwordLength, forKey: "passLength")
                            
                            completion(value)
                        } else {
                            self?.statusMessage = "Invalid password format in value"
                            completion(nil)
                        }
                    } else {
                        // Если не JSON, пробуем использовать как есть
                        if self?.isValidPassword(trimmedString) == true {
                            self?.statusMessage = "Password caught successfully"
                            self?.lastFetchTime = Date()
                            completion(trimmedString)
                        } else {
                            self?.statusMessage = "Invalid password format received"
                            completion(nil)
                        }
                    }
                } else {
                    self?.statusMessage = "Could not decode response"
                    completion(nil)
                }
            }
        }
        
        task.resume()
    }
    
    func clearStatus() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.statusMessage = ""
        }
    }
    
    deinit {
        stopMonitoring()
    }
}

 