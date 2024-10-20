import { NativeModules, Platform } from 'react-native';

// Define the KKOptions interface
interface KKOptions {
  apiKey: string; // required
  deviceID: number;
  displayName?: string;
  displayTagline?: string;
  homeAwayHide?: boolean;
  seatNumberEditHide?: boolean;
  homeAwaySelection?: string;
}

const LINKING_ERROR =
  `The package 'krowdkinect-react-native' doesn't seem to be linked. Make sure: \n\n` +
  Platform.select({ ios: "- You have run 'pod install'\n", default: '' }) +
  '- You rebuilt the app after installing the package\n' +
  '- You are not using Expo Go\n';

const { KrowdkinectReactNative } = NativeModules
  ? NativeModules.KrowdkinectReactNative
  : new Proxy(
      {},
      {
        get() {
          throw new Error(LINKING_ERROR);
        },
      }
    );
    
export function launchKrowdKinect(options: KKOptions): void {
  if (KrowdkinectReactNative) {
    KrowdkinectReactNative.launch(options);
  } else {
    console.warn('KrowdkinectReactNative is not available.');
  }
}
