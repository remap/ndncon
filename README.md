NdnCon
======

NdnCon (NDN COnfereNcing tool) is a MacOS Cocoa application which uses [NDN-RTC](https://github.com/remap/ndnrtc) library for providing audio/video conferencing functionality. 
See project's [Wiki](https://github.com/remap/ndncon/wiki) for more information.

Dependencies
===
NdnCon depends on a number of libraries:
- [NDN-RTC](https://github.com/remap/ndnrtc)
- [NDN-CPP](https://github.com/named-data/ndn-cpp)
- [NDN Chrono Sync 2013 & Chat](https://github.com/zhehaowang/ConferenceDiscovery)

Xcode project configuration
===
The main burden of configuring NdnCon Xcode project is to set up all dependencies' paths correctly and make sure executable is linked against appropriate library versions. 

0. Make sure [dependencies](#dependencies) are checked out and compiled
1. Checkout NdnCon repository and submodules

    <pre>
        $ git clone https://github.com/remap/ndncon.git && cd ndncon
        $ git submodule init && git submodule update</pre>

2. Open **NdnCon.xcodeproj** project in Xcode
> NdnCon Xcode project has two main targets: **NdnCon** and **NdnCon-Release**.
> **NdnCon** target is the main target for debugging purposes adn trying out NdnCon application. **NdnCon-Release** might be used for compiling more efficient, optimized and debug-symbols-free version of the NdnCon.
> Further explanation will be focused on configuring **NdnCon** target. However **NdnCon-Release** can be configured in similar way with minor differences. Those differences will be highlighted.

3. The first step to configure the project is to set up search paths for the dependent libraries. There are several project variables created for convenience:
  - Open project preferences
  - Make sure "NdnCon" project is selected in the left sidebar (not "NdnCon" target!)
  - Select "Build settings" tab
  - Scroll down to "User Defined" section
  - Set variables to dependencies paths:
    - **BOOST_INCLUDE_PATH** - path to boost library headers
    - **BOOST_LIB_PATH** - path to boost libraries
    - **NDNCHAT_INCLUDE_PATH** - path to NDN Chrono Sync 2013 & Chat library headers
    - **NDNCHAT_LIB_PATH** - path to NDN Chrono Sync 2013 & Chat libraries
    - **NDNCPP_INCLUDE_PATH** - path to NDN-CPP library headers
    - **NDNCPP_INCLUDE_PATH** - path to NDN-CPP library
    - **NDNRTC_INCLUDE_PATH** - path to NDN-RTC library include headers
    - **NDNRTC_LIB_PATH** - path to NDN-RTC library
    ![Project variables](/../readme-screenshots/screenshots/variables.png?raw=true)

4. Next step is to add dependent libraries to linking phase of the project. NdnCon depends on 3 groups of libraries, each of which may contain 1 or more dependent libraries:
  - NDN-RTC:
    - libndnrtc.dylib
  - NDN-CPP:
    - libndn-cpp.dylib
  - NDN Chrono Sync 2013 & Chat:
    - libentity-discovery.dylib
    - libchrono-chat2013.dylib
  
  In order to add dependent libraries to the project:
    - Open **NdnCon** target settings
    - Select "Buidl phases" tab
    - Expand "Link Binary With Libraries" section
    - Drag dependent libraries onto this phase
> For **NdnCon-Release** target, make sure you're dragging **release** versions of dependent libraries

    ![Project libraries](/../readme-screenshots/screenshots/libraries.png?raw=true)

5. Build NdnCon by pressing "Command + B"
  













