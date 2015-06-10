## react-native-local-image-manager
A React Native module for downloading and resizing images natively.

### Add it to your project
1. Run `npm install react-native-local-image-manager --save`
2. Add `RCTLocalImageManager.m` to your Xcode project.

### Usage
```
var { NativeModules } = require('react-native');
var LocalImageManager = require('NativeModules').LocalImageManager;

// Resize a local image
var options = {
    uri: '<LOCAL FILE PATH>',
    width: 100,
    height: 100,
    quality: 0.5,
    filename: 'myfile.jpg',
};

LocalImageManager.resize(options, function (results) {
    // results is the filesystem path of the resized image
    console.log(results);
});



// Remove the resized local image
LocalImageManager.remove('<LOCAL FILE PATH>');



// Download an image and store it locally
var options = {
    uri: 'https://www.google.com/images/srpr/logo11w.png',
    filename: 'google_logo.png',
};

LocalImageManager.download(options, function (results) {
    // results is the filesystem path of the downloaded image
    console.log(results);
});
```