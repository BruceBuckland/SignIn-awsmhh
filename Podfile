source 'https://github.com/CocoaPods/Specs.git'

platform :ios, '8.0'
use_frameworks!


def mobile_pods
    pod 'AWSCognito'
    pod 'AWSCognitoIdentityProvider'
    pod 'AWSDynamoDB'
    pod 'FBSDKLoginKit', '~> 4.13.1'
    pod 'FBSDKCoreKit', '~> 4.13.1'
    pod 'GoogleSignIn', '~> 4.0.0'
    pod 'AWSMobileAnalytics'
    pod 'AWSSNS', '~>2.4.6'
    pod 'AWSS3', '~>2.4.6'
    pod 'AWSLambda', '~>2.4.6'
    #     pod 'Bolts-Swift', '~>1.2.0' Bolts 1.8.4 comes with AWS?



end

target :'SignIn' do
    mobile_pods
end



target :'MySampleApp' do
    mobile_pods
    pod 'GoogleSymbolUtilities'
    pod 'GoogleUtilities'
    pod 'GoogleNetworkingUtilities'
    pod 'GoogleAuthUtilities'
    pod 'GoogleAppUtilities'



end
