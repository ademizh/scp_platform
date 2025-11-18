// module.exports = {
//     plugins: {
//         "@tailwindcss/postcss": {},
//         autoprefixer: {},
//     },
// };

// /** @type {import('postcss').Config} */
// const config = {
//     plugins: {
//         tailwindcss: {},
//         autoprefixer: {},
//     },
// };

// export default config;

// /** @type {import('tailwindcss').Config} */
// module.exports = {
//     plugins: {
//         tailwindcss: {},
//         autoprefixer: {},
//     },
// };


/** @type {import('postcss').Config} */
module.exports = {
    plugins: {
        '@tailwindcss/postcss': {}, // <-- This is the new, correct package
        autoprefixer: {},
    },
};
