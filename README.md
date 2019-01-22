# Chrome extension

This is a experimental project :exclamation:

This project is bootstrapped with [Create Elm App](https://github.com/halfzebra/create-elm-app).

An Magnetis chrome extension, wich shows a profile overview, with reminder alert.

Made with

![<3 elm](https://elm-lang.org/favicon.ico)

| Extension | My Wallet | Login |
| ---- | ---- | ---- |
| ![icon](https://user-images.githubusercontent.com/1855125/51565882-4e4ca500-1e7a-11e9-82e6-0140d9940dd5.png) | ![my-wallet](https://user-images.githubusercontent.com/1855125/51565881-4db40e80-1e7a-11e9-8b2c-0635dd83d47a.png) | ![login](https://user-images.githubusercontent.com/1855125/51565883-4e4ca500-1e7a-11e9-9f27-8e4ed18893ce.png) |


## Setup

``` sh
git clone https://github.com/magnetis/mag-chrome-extension.git
npm install
elm install
```

## Using

``` sh
npm start
```

## Deploying

``` sh
npm run build
```

- This will create a `build` folder with the compiled application
- This folder contains a PWA version
- To use as a chrome extension, just replace the `manifest.json` file with the following content:

``` json
{
  "name": "Magnetis Summary",
  "short_name": "MagSummary",
  "version": "1.0",
  "description": "Build an Extension!",
  "manifest_version": 2,
  "browser_action": {
    "default_popup": "index.html"
  },
  "permissions": ["activeTab", "notifications"],
  "background": {
    "scripts": ["background.js"]
  },
  "icons": {
    "48": "images/icons/logo-48.jpg",
    "72": "images/icons/logo-72.jpg",
    "144": "images/icons/logo-144.jpg"
  }
}
```