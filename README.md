# ETH Study Planner

## Build Instructions
1. Download and install Xcode. We use version 16.1.
2. Clone this repository in the folder of your preference.
3. After opening the project set the development team under "Signing & Capabilities" of the main target.

### Configuration
We use Swift Package Manager for dependency management, eliminating the need for manual installation of external packages.

The study plan is stored locally on the device using CoreData, while the catalog of available courses is hosted on Firestore. To fully run the application, follow this [official Firebase setup guide](https://firebase.google.com/docs/ios/setup) to configure Firebase for your environment.
Additionally, populate Firestore with sample data under the path ```courses/[course-id]```. The required data structure for Firestore course documents can be referenced in ```AddCourseViewModel.swift```. 

Moreover, add a document ```general/lastCourseUpdate``` which contains the field ```date```. This date serves as a reference for the local cache, indicating the last update of the courses and determining when a refresh is required.

Finally, you should configure your Firebase project to use AppCheck. To do so, follow this [official AppCheck setup guide](https://firebase.google.com/docs/app-check/ios/app-attest-provider).

# How to Contribute
We greatly appreciate your interest in contributing to the app. Below, you will find a concise guide on how you can support the project and get involved effectively.

## Beta Testing
Would you like to explore the latest version of the ETH Study Planner before its official release? We invite you to [join our TestFlight group](https://testflight.apple.com/join/zK7jb1FK) and help shape the app's development. Please be aware that this pre-release version may contain bugs. Your feedback on these updates is highly valued and greatly appreciated.

## Reporting Bugs & Asking Questions
Found a bug or want to suggest a feature? We would appreciate it if you could go to the Issues page and open a new issue, adding relevant information, labels and screenshots if possible.

## Submitting Code Changes
If you'd like to explore tasks, feel free to browse the Issues page and pick something that interests you. To avoid duplicating efforts, please leave a comment on the issue you intend to work on to let us know. For new features or significant changes, we recommend waiting for feedback before proceeding, as the issue may no longer align with the project’s goals.

For minor changes, you’re welcome to submit a pull request directly without prior notification.

## Getting in touch
If you have questions about getting setup or just want to say hi, write me on discord (@luca.bl) or use the contact form on [studyplanner.ch](studyplanner.ch).

## Contributors
The project was developed as part of the ‘Human Computer Interaction’ lecture at ETH Zurich in the autumn semester of 2024. ETH Study Planner is neither supported by ETH nor by VSETH, its a private initiative run by Students.
Team members: [@AlexFalter](https://github.com/AlexFalter), [@julius-domagk](https://github.com/julius-domagk), [@svenebner](https://github.com/svenebner), [@jh-eth](https://github.com/jh-eth), [@sven6666](https://github.com/sven6666), [@lucakbb](https://github.com/lucakbb)

## License
ETH Study Planner is an Open Source project covered by the [GNU General Public License version 2](/LICENSE)

