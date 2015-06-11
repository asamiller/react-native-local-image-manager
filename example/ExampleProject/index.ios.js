/**
 * Sample React Native App
 * https://github.com/facebook/react-native
 */
'use strict';

var React = require('react-native');
var {
  AppRegistry,
  StyleSheet,
  Text,
  Image,
  View,
  TouchableOpacity,
} = React;

var LocalImageManager = require('NativeModules').LocalImageManager;

var ExampleProject = React.createClass({

  getInitialState: function() {
    return {
      imageResult: null,
      resizeResult: null,
    };
  },

  render: function() {
    var imageElement;
    var resizeElement;

    if (this.state.imageResult) {
      imageElement = (
        <Image source={{uri: this.state.imageResult}} style={styles.image} />
      );
    }

    if (this.state.resizeResult) {
      resizeElement = (
        <Image source={{uri: this.state.resizeResult}} style={styles.image} />
      );
    }
    return (
      <View style={styles.container}>
        <TouchableOpacity onPress={this.downloadImage}>
          <Text style={styles.welcome}>
            Download Image
          </Text>
        </TouchableOpacity>
        {imageElement}

        <TouchableOpacity onPress={this.resizeImage}>
          <Text style={styles.welcome}>
            Resize Image
          </Text>
        </TouchableOpacity>
        {resizeElement}
      </View>
    );
  },

  downloadImage () {
    var options = {
      uri: 'https://igcdn-photos-a-a.akamaihd.net/hphotos-ak-xfa1/t51.2885-15/11242865_1062704387091208_1538328286_n.jpg',
      filename: 'pup.jpg',
    };

    LocalImageManager.download(options, (results) => {
      // results is the filesystem path of the downloaded image
      console.log(results);
      this.setState({ imageResult: results });
    });
  },

  resizeImage () {
    if (!this.state.imageResult) throw new Error('no image downloaded');

    var options = {
      uri: this.state.imageResult,
      width: 100,
      height: 100,
      quality: 0.5,
      filename: 'small.jpg',
    };

    console.log(options);

    LocalImageManager.resize(options, (results) => {
      // results is the filesystem path of the resized image
      console.log(results);
      this.setState({ resizeResult: results });
    });    
  }
});

var styles = StyleSheet.create({
  container: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#F5FCFF',
  },
  welcome: {
    fontSize: 20,
    textAlign: 'center',
    margin: 10,
  },
  image: {
    width: 200,
    height: 200,
  },
});

AppRegistry.registerComponent('ExampleProject', () => ExampleProject);
