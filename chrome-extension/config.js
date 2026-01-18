// Config for Illustraitor AI Extension
const CONFIG = {
    // API URL - ваш сервер на Render
    API_URL: 'https://illustraitor-ai-generator.onrender.com',
    // Endpoints
    ENDPOINTS: {
        GENERATE: '/generate',
        HEALTH: '/health',
        VALIDATE_OPENAI: '/validate/openai',
        VALIDATE_UNSPLASH: '/validate/unsplash'
    },
    // Timeout in milliseconds
    TIMEOUT: 45000,
    // Default styles for DALL-E
    DEFAULT_STYLES: [
        { id: 'fantasy', name: 'Фантастика' },
        { id: 'realistic', name: 'Реализм' },
        { id: 'minimalist', name: 'Минимализм' },
        { id: 'abstract', name: 'Абстракция' },
        { id: 'digital-art', name: 'Цифровое искусство' },
        { id: 'photographic', name: 'Фотографический' }
    ],
    // Unsplash options
    UNSPLASH_OPTIONS: {
        COLORS: [
            { id: null, name: 'Любой цвет' },
            { id: 'black_and_white', name: 'Черно-белый' },
            { id: 'black', name: 'Черный' },
            { id: 'white', name: 'Белый' },
            { id: 'yellow', name: 'Желтый' },
            { id: 'orange', name: 'Оранжевый' },
            { id: 'red', name: 'Красный' },
            { id: 'purple', name: 'Фиолетовый' },
            { id: 'magenta', name: 'Пурпурный' },
            { id: 'green', name: 'Зеленый' },
            { id: 'teal', name: 'Бирюзовый' },
            { id: 'blue', name: 'Синий' }
        ],
        ORIENTATIONS: [
            { id: null, name: 'Любая ориентация' },
            { id: 'landscape', name: 'Горизонтальная' },
            { id: 'portrait', name: 'Вертикальная' },
            { id: 'squarish', name: 'Квадратная' }
        ]
    }
};
export default CONFIG;
