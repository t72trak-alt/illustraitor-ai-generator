// ====================
// МОДУЛЬ ХРАНЕНИЯ (chrome.storage)
// ====================
class StorageManager {
    static async getKeys() {
        return new Promise((resolve) => {
            chrome.storage.local.get([CONFIG.STORAGE_KEYS.OPENAI_KEY, CONFIG.STORAGE_KEYS.UNSPLASH_KEY], (result) => {
                resolve({
                    openaiKey: result[CONFIG.STORAGE_KEYS.OPENAI_KEY] || '',
                    unsplashKey: result[CONFIG.STORAGE_KEYS.UNSPLASH_KEY] || ''
                });
            });
        });
    }
    static async saveKey(type, key) {
        const storageKey = type === 'openai' 
            ? CONFIG.STORAGE_KEYS.OPENAI_KEY 
            : CONFIG.STORAGE_KEYS.UNSPLASH_KEY;
        return new Promise((resolve) => {
            chrome.storage.local.set({ [storageKey]: key }, () => {
                resolve(true);
            });
        });
    }
    static async deleteKey(type) {
        const storageKey = type === 'openai' 
            ? CONFIG.STORAGE_KEYS.OPENAI_KEY 
            : CONFIG.STORAGE_KEYS.UNSPLASH_KEY;
        return new Promise((resolve) => {
            chrome.storage.local.remove(storageKey, () => {
                resolve(true);
            });
        });
    }
}
// ====================
// МОДУЛЬ УТИЛИТ
// ====================
class Utils {
    static showMessage(elementId, message, type = 'info') {
        const element = document.getElementById(elementId);
        if (!element) return;
        const colors = {
            info: 'var(--blue)',
            success: 'var(--green)',
            warning: 'var(--yellow)',
            error: 'var(--red)'
        };
        element.innerHTML = `<i class="fas fa-${type === 'success' ? 'check-circle' : type === 'error' ? 'exclamation-circle' : 'info-circle'}"></i> ${message}`;
        element.style.color = colors[type] || colors.info;
        element.style.borderLeft = `3px solid ${colors[type] || colors.info}`;
        element.style.padding = '10px';
    }
    static clearMessage(elementId) {
        const element = document.getElementById(elementId);
        if (element) {
            element.innerHTML = '';
            element.style.borderLeft = 'none';
        }
    }
    static showGlobalStatus(message, type = 'info') {
        Utils.showMessage('global-status', message, type);
    }
    static validateOpenAIKey(key) {
        return key.trim().startsWith('sk-') && key.length > 20;
    }
    static validateUnsplashKey(key) {
        return key.trim().length >= 10;
    }
}
// ====================
// МОДУЛЬ API
// ====================
class APIManager {
    static async validateKey(type, key) {
        const endpoint = type === 'openai' 
            ? CONFIG.ENDPOINTS.VALIDATE_OPENAI 
            : CONFIG.ENDPOINTS.VALIDATE_UNSPLASH;
        try {
            const response = await fetch(`${CONFIG.API_BASE_URL}${endpoint}`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ key })
            });
            const result = await response.json();
            return { valid: response.ok, message: result.detail || result.error || 'Неизвестная ошибка' };
        } catch (error) {
            return { valid: false, message: `Ошибка сети: ${error.message}` };
        }
    }
    static async generateImage(source, prompt, style, apiKey) {
        try {
            const response = await fetch(`${CONFIG.API_BASE_URL}${CONFIG.ENDPOINTS.GENERATE}`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({
                    source,
                    prompt,
                    style: source === 'openai' ? style : undefined,
                    color: source === 'unsplash' ? style : undefined,
                    openai_key: source === 'openai' ? apiKey : undefined,
                    unsplash_key: source === 'unsplash' ? apiKey : undefined
                })
            });
            const result = await response.json();
            if (!response.ok) {
                throw new Error(result.detail || result.error || 'Ошибка генерации');
            }
            return { success: true, url: result.url, source };
        } catch (error) {
            return { success: false, message: error.message };
        }
    }
}
// ====================
// ОСНОВНАЯ ЛОГИКА
// ====================
document.addEventListener('DOMContentLoaded', async function() {
    // Инициализация стилей
    const styleSelect = document.getElementById('openai-style');
    CONFIG.STYLES.forEach(style => {
        const option = document.createElement('option');
        option.value = style.id;
        option.textContent = style.name;
        styleSelect.appendChild(option);
    });
    // Загрузка сохранённых ключей
    const keys = await StorageManager.getKeys();
    document.getElementById('openai-key').value = keys.openaiKey;
    document.getElementById('unsplash-key').value = keys.unsplashKey;
    // ====================
    // ОБРАБОТЧИКИ OPENAI
    // ====================
    // Сохранить ключ OpenAI
    document.getElementById('save-openai').addEventListener('click', async function() {
        const key = document.getElementById('openai-key').value.trim();
        const statusElement = 'status-openai';
        Utils.clearMessage(statusElement);
        if (!key) {
            Utils.showMessage(statusElement, '❌ Ошибка: ключ OpenAI не может быть пустым', 'error');
            return;
        }
        if (!Utils.validateOpenAIKey(key)) {
            Utils.showMessage(statusElement, '❌ Неверный формат ключа OpenAI. Должен начинаться с sk-', 'error');
            return;
        }
        await StorageManager.saveKey('openai', key);
        Utils.showMessage(statusElement, '✅ Ключ OpenAI сохранён локально', 'success');
        Utils.showGlobalStatus('Ключ OpenAI сохранён.', 'success');
    });
    // Удалить ключ OpenAI
    document.getElementById('delete-openai').addEventListener('click', async function() {
        await StorageManager.deleteKey('openai');
        document.getElementById('openai-key').value = '';
        Utils.showMessage('status-openai', '🗑️ Ключ OpenAI удалён', 'warning');
        Utils.showGlobalStatus('Ключ OpenAI удалён.', 'warning');
    });
    // Проверить ключ OpenAI
    document.getElementById('validate-openai').addEventListener('click', async function() {
        const key = document.getElementById('openai-key').value.trim();
        const statusElement = 'status-openai';
        Utils.clearMessage(statusElement);
        if (!key) {
            Utils.showMessage(statusElement, '❌ Ошибка: введите ключ для проверки', 'error');
            return;
        }
        Utils.showMessage(statusElement, '🔍 Проверяю ключ OpenAI...', 'info');
        const result = await APIManager.validateKey('openai', key);
        if (result.valid) {
            Utils.showMessage(statusElement, '✅ Ключ OpenAI действителен', 'success');
            Utils.showGlobalStatus('Ключ OpenAI проверен.', 'success');
        } else {
            Utils.showMessage(statusElement, `❌ Ошибка: ${result.message}`, 'error');
            Utils.showGlobalStatus('Ошибка проверки ключа OpenAI.', 'error');
        }
    });
    // Сгенерировать изображение через OpenAI
    document.getElementById('generate-openai').addEventListener('click', async function() {
        const key = document.getElementById('openai-key').value.trim();
        const prompt = document.getElementById('openai-prompt').value.trim();
        const style = document.getElementById('openai-style').value;
        const statusElement = 'status-openai';
        Utils.clearMessage(statusElement);
        // Валидация
        if (!key) {
            Utils.showMessage(statusElement, '❌ Ошибка: введите ключ OpenAI', 'error');
            return;
        }
        if (!prompt) {
            Utils.showMessage(statusElement, '❌ Ошибка: введите запрос для генерации', 'error');
            return;
        }
        Utils.showMessage(statusElement, '🎨 Генерирую изображение... Это займет 10-30 секунд', 'info');
        Utils.showGlobalStatus('Генерация через DALL-E 3 начата...', 'info');
        const result = await APIManager.generateImage('openai', prompt, style, key);
        if (result.success) {
            Utils.showMessage(statusElement, '✅ Изображение успешно сгенерировано!', 'success');
            Utils.showGlobalStatus('Генерация завершена.', 'success');
            showResultImage(result.url, 'openai');
        } else {
            Utils.showMessage(statusElement, `❌ Ошибка: ${result.message}`, 'error');
            Utils.showGlobalStatus('Ошибка генерации.', 'error');
        }
    });
    // ====================
    // ОБРАБОТЧИКИ UNSPLASH
    // ====================
    // Сохранить ключ Unsplash
    document.getElementById('save-unsplash').addEventListener('click', async function() {
        const key = document.getElementById('unsplash-key').value.trim();
        const statusElement = 'status-unsplash';
        Utils.clearMessage(statusElement);
        if (!key) {
            Utils.showMessage(statusElement, '❌ Ошибка: ключ Unsplash не может быть пустым', 'error');
            return;
        }
        if (!Utils.validateUnsplashKey(key)) {
            Utils.showMessage(statusElement, '❌ Неверный формат ключа Unsplash. Минимум 10 символов', 'error');
            return;
        }
        await StorageManager.saveKey('unsplash', key);
        Utils.showMessage(statusElement, '✅ Ключ Unsplash сохранён локально', 'success');
        Utils.showGlobalStatus('Ключ Unsplash сохранён.', 'success');
    });
    // Удалить ключ Unsplash
    document.getElementById('delete-unsplash').addEventListener('click', async function() {
        await StorageManager.deleteKey('unsplash');
        document.getElementById('unsplash-key').value = '';
        Utils.showMessage('status-unsplash', '🗑️ Ключ Unsplash удалён', 'warning');
        Utils.showGlobalStatus('Ключ Unsplash удалён.', 'warning');
    });
    // Проверить ключ Unsplash
    document.getElementById('validate-unsplash').addEventListener('click', async function() {
        const key = document.getElementById('unsplash-key').value.trim();
        const statusElement = 'status-unsplash';
        Utils.clearMessage(statusElement);
        if (!key) {
            Utils.showMessage(statusElement, '❌ Ошибка: введите ключ для проверки', 'error');
            return;
        }
        Utils.showMessage(statusElement, '🔍 Проверяю ключ Unsplash...', 'info');
        const result = await APIManager.validateKey('unsplash', key);
        if (result.valid) {
            Utils.showMessage(statusElement, '✅ Ключ Unsplash действителен', 'success');
            Utils.showGlobalStatus('Ключ Unsplash проверен.', 'success');
        } else {
            Utils.showMessage(statusElement, `❌ Ошибка: ${result.message}`, 'error');
            Utils.showGlobalStatus('Ошибка проверки ключа Unsplash.', 'error');
        }
    });
    // Поиск фото в Unsplash
    document.getElementById('search-unsplash').addEventListener('click', async function() {
        const key = document.getElementById('unsplash-key').value.trim();
        const query = document.getElementById('unsplash-query').value.trim();
        const color = document.getElementById('unsplash-color').value;
        const statusElement = 'status-unsplash';
        Utils.clearMessage(statusElement);
        // Валидация
        if (!key) {
            Utils.showMessage(statusElement, '❌ Ошибка: введите ключ Unsplash', 'error');
            return;
        }
        if (!query) {
            Utils.showMessage(statusElement, '❌ Ошибка: введите поисковый запрос', 'error');
            return;
        }
        Utils.showMessage(statusElement, '🔍 Ищу фото в Unsplash...', 'info');
        Utils.showGlobalStatus('Поиск в Unsplash...', 'info');
        const result = await APIManager.generateImage('unsplash', query, color, key);
        if (result.success) {
            Utils.showMessage(statusElement, '✅ Фото найдено!', 'success');
            Utils.showGlobalStatus('Поиск завершён.', 'success');
            showResultImage(result.url, 'unsplash');
        } else {
            Utils.showMessage(statusElement, `❌ Ошибка: ${result.message}`, 'error');
            Utils.showGlobalStatus('Ошибка поиска.', 'error');
        }
    });
    // ====================
    // ОБРАБОТКА РЕЗУЛЬТАТОВ
    // ====================
    function showResultImage(url, source) {
        const resultContainer = document.getElementById('result-container');
        const resultImage = document.getElementById('result-image');
        const downloadBtn = document.getElementById('download-btn');
        resultImage.src = url;
        resultContainer.classList.remove('hidden');
        // Настройка скачивания
        downloadBtn.onclick = function() {
            const link = document.createElement('a');
            link.href = url;
            link.download = `illustraitor_${source}_${Date.now()}.jpg`;
            link.click();
        };
    }
    // Закрыть результат
    document.getElementById('close-result').addEventListener('click', function() {
        document.getElementById('result-container').classList.add('hidden');
    });
    // Проверка здоровья API при загрузке
    try {
        const healthResponse = await fetch(`${CONFIG.API_BASE_URL}${CONFIG.ENDPOINTS.HEALTH}`);
        if (healthResponse.ok) {
            Utils.showGlobalStatus('API сервер доступен. Готов к работе.', 'success');
        } else {
            Utils.showGlobalStatus('⚠️ API сервер недоступен', 'warning');
        }
    } catch {
        Utils.showGlobalStatus('❌ Нет соединения с API сервером', 'error');
    }
});
