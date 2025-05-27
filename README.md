# **Project Giggle Mobile App Setup Guide**

Welcome to the setup guide for Project Giggle. This document will walk you through the process of setting up your development environment, cloning the project, and running the app.

## 01. Prerequisites

Before starting, ensure you have the following tools installed on your computer.

- [Flutter SDK 3.16.5](https://docs.flutter.dev/release/archive) Flutter 3.16.5 Stable
- [Git](https://git-scm.com/book/en/v2/Getting-Started-Installing-Git)
- [Visual Studio Code](https://code.visualstudio.com/) (VS Code) with Dart and Flutter extensions
- [Android Studio](https://developer.android.com/studio) with the Flutter plugin

## 02. Setting Up Development Environment

**Preparing for Android Studio and Emulator Installation:**

Ensure Adequate Hard Disk Space: Before starting, ensure that you have at least 20GB of free hard disk space. This space is necessary for the Android Studio installation, SDKs, emulators, and system images.

Check System Requirements: Ensure that your computer meets the minimum system requirements to run Android Studio efficiently. As of my last update, these requirements include:

- **OS:** Windows (10 or later), macOS (10.14 or later), GNOME or KDE desktop on Linux
- **RAM:** Minimum 4 GB RAM, 8 GB RAM recommended
- **Disk Space:** Minimum 2 GB of available disk space, 4 GB Recommended (500 MB for IDE + 1.5 GB for Android SDK and emulator system image)
- **Screen Resolution:** 1280 x 800 minimum screen resolution

**Overall, you need 20GB on your C: drive to run Flutter and all plugins with C: drive free space for smooth running.**

For the latest requirements, check the [official Android Studio download page.](https://developer.android.com/codelabs/basic-android-kotlin-compose-install-android-studio#0)

## 03. **Enable developer mode only Windows:**

Here’s how to execute the command:

    ms-settings:developers

---

Press the Windows key on your keyboard.

2. Type “Command Prompt” or “cmd” in the search bar.

3. Right-click on “Command Prompt” in the search results.

4. Select “Run as administrator” to open an elevated command prompt.

5. Copy the command mentioned above and paste it into the command prompt window.

6. Press Enter to execute the command.

This will open the “Developer options” settings page in the Windows Settings app, where you can enable or disable Developer Mode and access other developer-related settings.

## 04. **Download Java/JDK:**

Visit the Oracle JDK download page and download newest version: (https://www.oracle.com/java/technologies/).

1. Accept the license agreement.
2. Download the JDK appropriate for your operating system (e.g., Windows, macOS, Linux).
3. Run the downloaded JDK installer.
4. Follow the installation instructions provided by the installer.
5. Choose the installation directory for the JDK.
6. Complete the installation process.
7. Open the Start menu and search for “Environment Variables.”
8. Click on “Edit the system environment variables.”
9. Click the “Environment Variables” button at the bottom.
10. Under the “System Variables” section, click “New” to add a new variable.
11. Set the variable name as JAVA_HOME.
12. Set the variable value as the path to your JDK installation directory with your version path (e.g., C:\Program Files\Java\jdk-17\).
13. Click “OK” to save the changes.

## 05. **Verify JDK Installation**

1. Open a command prompt or PowerShell.
2. Type java — version and press Enter.

Command:

    java — version

---

3. Verify that the installed JDK version is displayed without any errors.

After completing these steps, you have successfully downloaded and installed the Java Development Kit (JDK) on your system. Android Studio should now be able to locate and utilize the JDK for Flutter app development.

## 06. **Installing Android Studio(for Android development) and Setting Up a New Emulator:**

Install Android Studio: If you haven't already installed Android Studio, download it from the official website and follow the installation instructions.

1. Download and install [Android Studio](https://developer.android.com/studio).
2. Install the Flutter plugin: Preferences \> Plugins \> Flutter, then restart Android Studio.
3. Install [Android toolchain](https://docs.flutter.dev/get-started/install/help#cmdline-tools-component-is-missing) for Android Studio

![](https://cdn.discordapp.com/attachments/1006536173189079070/1200420065888182302/image.png?ex=65c61d4e&is=65b3a84e&hm=02f8493e62a9a566c8f38c1e68202135a1951135a56acc14dd0a9bd22b29bb94&)

1. Open AVD Manager: In Android Studio, access the AVD (Android Virtual Device) Manager.
2. Remove Default Device: In the AVD Manager, locate the default device, click on the 'Actions' menu, and select 'Delete' to remove it.
3. Create a New Virtual Device:
4. Click "Create Virtual Device".
5. Choose 'Pixel 6a' from the device list. If not available, download its profile.
6. Click "Next".
7. Select System Image (SDK):
8. Choose 'API 33' (Tiramisu - Android 13). Download it if necessary.
9. After the download, select this system image and click "Next".
10. Configure and Finish:
11. Name the emulator (e.g., "Pixel 6a API 33").
12. Adjust settings as needed.
13. Click "Finish".

Launch the New Emulator: In the AVD Manager, start your new 'Pixel 6a API 33' emulator.

## 07. **Setting Up Flutter in VSCode(recommended code editor) with Android Studio Emulator:**

1. **Install Flutter and Dart Plugins in VSCode:**

1. Download and install [Visual Studio Code](https://code.visualstudio.com/) and Open VSCode
1. Go to the Extensions view by clicking on the square icon in the sidebar or pressing Ctrl+Shift+X.
1. Search for 'Flutter' and install the Flutter plugin. This should automatically install the Dart plugin as well.

1. **Verify Flutter Installation:**

1. Open a new terminal in VSCode (Terminal \> New Terminal).
1. Run flutter doctor to check if there are any dependencies you need to install. Follow any instructions given.

1. **Install Android Studio (If Not Already Installed):**

1. Download Android Studio from the official website.
1. Follow the below installation instructions.

1. **Set Up the Android Emulator in Android Studio(If Not Already Setuped)::**

1. Open Android Studio.
1. Go to the AVD Manager (Android Virtual Device Manager).
1. Create a new device (e.g., Pixel 6a) with your desired API (e.g., API 33 - Tiramisu).
1. Ensure you have downloaded the necessary system images and configurations.

1. **Start the Android Emulator:**

1. From the AVD Manager, start the emulator you set up.
1. Keep the emulator running.

1. **Configure Flutter and Dart in VSCode:**

1. Open your Flutter project in VSCode.
1. Ensure that the flutter and dart SDK paths are correctly set in the settings (if they are not automatically detected).

1. **Run Flutter App in Emulator:**

1. Open the command palette in VSCode (View \> Command Palette or Ctrl+Shift+P).
1. Type 'Flutter: Launch Emulator' and select the running emulator.
1. Once the emulator is selected and running, open the command palette again and run 'Flutter: Run Flutter Project in Current Directory'.

1. **Debugging and Hot Reload:**

1. VSCode will now build your Flutter app and install it on the emulator.
1. You can use VSCode's debugging tools to set breakpoints, inspect variables, and more.
1. Use the 'Hot Reload' feature by saving your files or using the appropriate command to see changes in real-time on the emulator.

## 08. **Set up Android licenses**

It’s important to note that accepting the licenses is a one-time process, usually performed during the initial setup or when adding new SDK components. It helps ensure compliance and grants you the legal permissions to utilize the Android SDK for development purposes.

Open a command prompt or PowerShell.
Run the following command to accept the Android licenses:

    flutter doctor — android-licenses

---

if any error comes, open Android studio, go to File->settings, drop down Appearence&Behavior then drop down Systems settings click on Android SDK and on right window, tap on SDK Tools, select Android SDK Command Line tools and download it. when downloaded, open terminal in Android studio/PowerShell and type above command again then accept packages licenses.

## 09. Running Flutter Doctor(Verify Flutter installation)

Before proceeding, it's important to ensure that your environment is correctly set up. Run the following command in your terminal:

    flutter doctor

---

## 10. Troubleshooting

If you encounter any issues, refer to the [Flutter documentation](https://flutter.dev/docs/get-started/install) and [Firebase documentation](https://firebase.google.com/docs). You can also seek help from your development team.

## 11. Contact

Praveen Aththanayake

[praveen@silverlineit.co](mailto:praveen@silverlineit.co)

[aththanayakempa@gmail.com](mailto:aththanayakempa@gmail.com)
