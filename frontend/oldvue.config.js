const { defineConfig } = require('@vue/cli-service');

module.exports = defineConfig({
  transpileDependencies: true,

  devServer: {
    https: true,           // enable HTTPS
    host: '0.0.0.0',      // allow access from other devices on LAN
    port: 8080,            // port number
  },
});