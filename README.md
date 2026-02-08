# Zeytin <🫒/>

Zeytin is an autonomous server solution backed by the power of the Dart language, completely eliminating external database dependencies. In traditional backend architectures, the server and database operate as separate layers, leading to network latency. Zeytin breaks down these barriers by embedding the database engine directly into the server's memory and processing threads. This client package, which you include in your Flutter project, acts as the bridge that enables encrypted and secure communication with this powerful engine on the server.

### What Happens in the Background?

Zeytin does not behave like a standard REST API. A custom disk-based NoSQL engine we call **Truck** runs on the server side. When you send data via the client, this data is not written to the disk as JSON, but in a machine language format compressed with a special **Binary Encoder**.

The system's most striking feature is its isolation architecture. Every user account has its own isolated thread and memory space on the server. This ensures that a very heavy data operation performed by person A never affects the application performance for person B. Thanks to **Persistent Index** maps held in RAM, data is read in milliseconds through direct coordinate targeting without scanning the disk.

### Why Should You Prefer Zeytin?

When you start developing with this package, you gain the following advantages over classic methods:

- **Total Independence:** You do not need to install or manage external services like MongoDB, PostgreSQL, or Redis for your project. Zeytin is sufficient on its own.
- **End-to-End Encryption:** The client library encrypts data using the AES-CBC standard with keys derived from the user's password before sending it to the server. Even the server administrator cannot see the content of the data without knowing the user password.
- **All-in-One Solution:** It comes ready with not just data storage, but complex modules your application needs, such as Chat, Social Media, E-Commerce, and Live Calls. You don't have to reinvent the wheel.
- **Real-Time Communication:** Every change in the database can be listened to instantly via WebSocket. You can make your application live without any extra setup.

# 2. Installation and Getting Started


Please prepare the server first, or try an existing one: [Zeytin Official Github](https://github.com/JeaFrid/Zeytin)

Including the Zeytin package in your project consists of more than just adding a line of code. Since the LiveKit-based audio and video calling modules included in the package require hardware access, your application must request the necessary permissions from the operating system.

### Adding the Package

First, while in your project directory via the terminal, run the following command to add the package to your `pubspec.yaml` file:

```bash
flutter pub add zeytin
```

### Platform Settings

Zeytin uses a powerful WebRTC infrastructure capable of accessing the device's camera and microphone. For these features to work without errors, you need to make small adjustments on the Android and iOS sides.

#### Android Configuration

Open the `android/app/src/main/AndroidManifest.xml` file in your project and add the following permissions right under the `<manifest>` tag:

```xml
<uses-feature android:name="android.hardware.camera" />
<uses-feature android:name="android.hardware.camera.autofocus" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
<uses-permission android:name="android.permission.CHANGE_NETWORK_STATE" />
<uses-permission android:name="android.permission.MODIFY_AUDIO_SETTINGS" />
```

#### iOS Configuration

User privacy is essential on the iOS side. You must specify why your application needs the camera and microphone by adding the following keys to your `ios/Runner/Info.plist` file:

```xml
<key>NSCameraUsageDescription</key>
<string>Camera access is required for video calling.</string>
<key>NSMicrophoneUsageDescription</key>
<string>Microphone access is required for voice calling.</string>
```

### Initializing the Zeytin Client

Once installation and permissions are complete, it is time to shake hands with the server. The Zeytin client should be managed via a single instance throughout the application.

Integrate the following code into your application's entry point:

```dart
import 'package:flutter/material.dart';
import 'package:zeytin/zeytin.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Creating the Zeytin client
  final zeytin = ZeytinClient();

  // Initiating connection with the server
  await zeytin.init(
    host: 'https://api.your-server.com',
    email: 'user@mail.com',
    password: 'strong_password'
  );

  runApp(MyApp(zeytin: zeytin));
}
```

### What Happened in the Background?

When you called the `init` function, a quite complex process operated in the background:

1.  **Server Check:** The client sent a ping to the Zeytin server at the host address you provided and checked if the server was up.
2.  **Identity and Truck Management:** The entered email and password information were transmitted to the server. The server checked if there was a Truck, meaning a user database file, matching this information. If the account existed, the server returned the Truck ID information belonging to that account. If the account did not exist, the server physically created a new isolated Truck file on the disk for you, stored your password by hashing it, and created your new identity.
3.  **Token Automation:** After a successful login, the server gave the client a temporary access key called a Token. `ZeytinClient` tracks the duration of this key internally and automatically talks to the server to renew the key just before it expires. You do not need to perform any additional session management.

# 3. Core and Authentication

The first step of working with Zeytin is to initialize the client and open a secure session. This section explains how connecting to the server, account creation, logging in, and token management work.

### Initializing the Client

At the starting point of your application (usually inside `main.dart`), you need to initialize the `ZeytinClient` class. This process performs the initial handshake with the server and checks the session status.

```dart
final zeytin = ZeytinClient();

await zeytin.init(
  host: 'https://api.example.com', // Your server address
  email: 'email@example.com',
  password: 'strong_password'
);
```

When the `init` function is called, the client follows these steps:

1.  It attempts to connect to the server at the given `host` address.
2.  If an account exists with the specified email and password, it logs in and receives a `token`.
3.  If no account exists, it automatically creates a new `Truck` (user database) and starts the session.
4.  It starts a background timer to ensure the token is automatically renewed before it expires.

### Token Management

Zeytin uses short-lived tokens (default is 2 minutes) to increase security. `ZeytinClient` manages these tokens on your behalf. After the `init` function is called, the client periodically sends requests to the server to renew the token. This way, your session does not drop even during long-term usage.

If you wish to access the token:

```dart
String?currentToken = zeytin.token;
```

If the token has expired or is invalid, the `getToken()` method automatically requests a new token.

# 4. Basic Database Operations

Data traffic between the Zeytin client and the server is conducted over fully encrypted packets, unlike classic methods. Although you might think you are sending a simple Dart map, in the background, this data is encrypted with the user's private key and transmitted to the server in that form. The server never decrypts this data; it only stores it in binary format. This ensures your data is completely secure both on the disk and on the network.

Our database structure consists of three basic components. At the top is the user's database file called **Truck**, inside it are categories called **Box** structures, and **Tag** keys which are the identity of each piece of data.

### Adding and Updating Data

In the Zeytin system, addition and update operations are managed by a single function. If there is no data at the specified box and tag address, it is created; if it exists, it is overwritten.

```dart
final response = await zeytin.addData(
  box: 'settings',
  tag: 'theme_preference',
  value: {
    'darkMode': true,
    'fontSize': 14,
    'lastUpdate': DateTime.now().toIso8601String()
  }
);

if (response.isSuccess) {
  print('Data was securely written to the disk.');
}
```

### Reading Data

When you want to read data, the server sends you the encrypted packet. The client library instantly decrypts this packet on your device and presents it to you as a meaningful Dart object.

```dart
final response = await zeytin.getData(
  box: 'settings',
  tag: 'theme_preference'
);

if (response.data != null) {
  final settings = response.data!;
  print('Dark Mode: ${settings['darkMode']}');
}
```

### Deleting Data

To permanently remove a piece of data from the server, it is sufficient to provide the box name and its tag.

```dart
await zeytin.deleteData(
  box: 'settings',
  tag: 'theme_preference'
);
```

### Batch Operations

Sometimes in your application, you may need to write hundreds of pieces of data at the same time. In this case, instead of going to the server separately for each piece of data, you should use the batch operation method. This method collects the data into a single encrypted packet and transmits it to the server in one go. This process reduces network traffic and significantly increases performance.

```dart
Map<String, Map<String, dynamic>> batchData = {
  'product_1': {'name': 'Laptop', 'price': 15000},
  'product_2': {'name': 'Mouse', 'price': 500},
  'product_3': {'name': 'Keyboard', 'price': 750},
};

await zeytin.addBatch(
  box: 'products',
  entries: batchData
);
```

### Live Data Monitoring

One of the most powerful features of the Zeytin package is its ability to listen to the database live. Thanks to WebSocket technology, when a change occurs in a box on the server, the server instantly notifies all subscribed devices of this change. On the Flutter side, you can easily connect this stream to your interface using StreamBuilder.

```dart
StreamBuilder(
  stream: zeytin.watchBox(box: 'messages'),
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      var event = snapshot.data!;
      // Event types are: PUT, UPDATE, DELETE
      print("New event: ${event['op']} - Tag: ${event['tag']}");

      return Text("Last message: ${event['data']}");
    }
    return CircularProgressIndicator();
  },
)
```

### Search and Filtering

To search within large data sets, you can use the special filtering engine running on the server side. This operation takes place in the server memory without pulling the data to the client.

**Prefix Search:** Checks if a text field starts with a specific group of letters.

```dart
var results = await zeytin.search(
  box: 'users',
  field: 'name',
  prefix: 'Jo' // Returns names like John, Jonathan
);
```

**Exact Match:** Returns records where a field's value matches exactly.

```dart
var results = await zeytin.filter(
  box: 'products',
  field: 'category',
  value: 'electronics'
);
```

# 5. User and Social

Zeytin is designed not just as a structure storing raw data, but as a platform to create social networks where users interact with each other. The `ZeytinUser` service allows you to manage the entire social graph, from profile management to following, blocking mechanisms to activity status.

To access this service, simply initialize the `ZeytinUser` class:

```dart
final userService = ZeytinUser(zeytin);
```

### Profile Management

You can use the `updateProfile` method to update user profile information. This operation updates not just the changed fields, but the entire user object.

```dart
// Get current user
ZeytinUserModel? currentUser = await userService.getProfile(userId: 'user_uid');

if (currentUser != null) {
  // Set new information
  final updatedUser = currentUser.copyWith(
    displayName: 'New Name',
    biography: 'Flutter developer.',
    avatarUrl: 'https://example.com/avatar.jpg'
  );

  // Send to server
  await userService.updateProfile(currentUser, updatedUser);
}
```

### Following and Unfollowing

Setting up a follow system similar to Instagram or Twitter is a one-line operation with Zeytin. These methods atomically update the `followers` and `following` lists of both users in the background.

```dart
// Follow a user
await userService.followUser(
  myUid: 'my_uid',
  targetUid: 'target_uid'
);

// Unfollow
await userService.unfollowUser(
  myUid: 'my_uid',
  targetUid: 'target_uid'
);
```

### Follow Status Check

To query the relationship between two users:

```dart
bool isFollowing = await userService.isFollow(
  myUid: 'my_uid',
  targetUid: 'target_uid'
);

if (isFollowing) {
  print("You are already following.");
}
```

### Blocking Mechanism

The blocking feature is indispensable for social platforms. In Zeytin, when you block a user, not only is profile access cut off; the system automatically **terminates all private chats between these two users and clears the message history** in the background. This provides comprehensive privacy.

```dart
await userService.blockUser(
  myUid: 'my_uid',
  targetUid: 'disturbing_uid'
);
```

To unblock:

```dart
await userService.unblockUser(
  myUid: 'my_uid',
  targetUid: 'disturbing_uid'
);
```

### Activity Status (Online/Offline)

You can use the `isActive` method to understand if a user is online. This method looks at the time of the user's last interaction with the server.

```dart
// Count as active if action taken within last 60 seconds
bool online = await userService.isActive(
  targetUser,
  thresholdSeconds: 60
);
```

To report the user's activity to the server in your application, you can call the following code at certain intervals:

```dart
await userService.updateUserActive(currentUser);
```

# 6. Chat and Messaging

One of the strongest muscles of the Zeytin package is its internal chat engine. Beyond just sending text; it offers all features expected in a modern messaging application like media sharing, read receipts, typing animations, and self-destructing messages with a single line of code.

The `ZeytinChat` service manages both one-on-one private chats and multi-participant group chats.

### Creating a Chat

To start a chat, you use the `createChat` method. Zeytin uses smart backend logic here; if you are starting a "private" chat between two people, the server first checks if there is a channel previously created between these two people. If it exists, it brings the old one; if not, it creates a new one.

```dart
final chatService = ZeytinChat(zeytin);

// Start a new chat
final response = await chatService.createChat(
  chatName: "Flutter Developers",
  type: ZeytinChatType.group, // or .private
  participants: [user1, user2, user3],
  admins: [user1], // Group admins
  themeSettings: {'color': 'blue'} // Chat specific theme
);

if (response.isSuccess) {
  print("Chat room ready: ${response.data['chatID']}");
}
```

During this process, the server writes the chat data to the `chats` box in the background and simultaneously goes to the `my_chats` index to update the participants' chat lists. Thanks to this bidirectional writing process, users' chat list queries take milliseconds.

### Sending a Message

Messages do not have to be just text. The `sendMessage` method supports different types like location, file, photo, or voice recording.

```dart
await chatService.sendMessage(
  chatId: 'chat_id',
  sender: currentUser,
  text: 'Hello friends, this is a test message.',
  messageType: ZeytinMessageType.text,
  // Optional features
  replyToMessageId: 'replied_message_id',
  selfDestructTimer: Duration(seconds: 30) // Deletes after 30 seconds
);
```

When the server receives this message in the background, it not only adds it to the message box but also updates the chat's `lastMessage` information and timestamp. Thus, you instantly see "Last message: Hello..." in your chat list.

### Real-Time Messaging

For the chat to flow live, you must subscribe to the WebSocket channel using the `listen` method. This way, when a new message arrives, it falls onto the screen without needing to refresh the page.

```dart
StreamBuilder(
  stream: chatService.listen(
    chatId: 'active_chat_id',
    onMessageReceived: (message) {
      print("New message arrived: ${message.text}");
    },
    onMessageUpdated: (message) {
      print("Message edited: ${message.messageId}");
    },
    onMessageDeleted: (messageId) {
      print("Message deleted: $messageId");
    },
  ),
  builder: (context, snapshot) {
    // Your UI Codes
    return MessageList();
  },
)
```

### Advanced Message Features

Zeytin offers tools that meet modern communication needs.

**Typing Indicator:**
To send "Typing..." information to others when the user touches the keyboard:

```dart
await chatService.setTyping(
  chatId: 'chat_id',
  user: currentUser,
  isTyping: true
);
```

**Read Receipt:**
To mark when a user has seen the message:

```dart
await chatService.markAsRead(
  messageId: 'message_id',
  userId: currentUser.uid
);
```

**Pinning Messages:**
To pin an important message to the top of the chat:

```dart
await chatService.pinMessage(
  messageId: 'message_id',
  chatId: 'chat_id',
  pinnedBy: currentUser.uid
);
```

**Emoji Reactions:**
To leave expressions like a heart or thumbs up on a message:

```dart
await chatService.addReaction(
  messageId: 'message_id',
  userId: currentUser.uid,
  emoji: '❤️'
);
```

# 7. Communities

The Zeytin infrastructure supports not just simple chats but also large-scale communities similar to Discord or Slack. Communities are advanced structures different from standard groups, featuring admins, set rules, and special announcement boards. The `ZeytinCommunity` service allows you to manage these structures.

### Creating a Community

When you create a community, the server performs two critical operations in the background. First, it writes the community data to the `communities` box, then assigns the creator as admin and adds the ID of this new community to the `my_communities` index in the participants' profiles.

```dart
final communityService = ZeytinCommunity(zeytin);

final response = await communityService.createCommunity(
  name: "Flutter Turkey",
  description: "Meeting point for Flutter developers.",
  photoURL: "https://example.com/logo.png",
  creator: currentUser, // Becomes admin
  participants: [currentUser, user2, user3],
  moreDataMap: {'category': 'Software', 'private': false}
);

if (response.isSuccess) {
  print("Community ID: ${response.data['id']}");
}
```

### Joining and Leaving

In the event users join or leave a community, the system does not only update the participant list within the community. It also updates the community list index in the user's own profile. This way, the query "Get communities the user is a member of" returns results in milliseconds instead of scanning the entire database.

```dart
// Join community
await communityService.joinCommunity(
  communityId: 'community_id',
  user: currentUser
);

// Leave community
await communityService.leaveCommunity(
  communityId: 'community_id',
  user: currentUser
);
```

### Announcement Board

The most distinguishing feature of communities is the **Board**. This is a special area where only admins can share content, while members can only view and mark as "seen". Separated from the chat flow, it is kept in the `community_boards` box.

**Sharing an Announcement (Admins Only):**

```dart
await communityService.sendBoardPost(
  communityId: 'community_id',
  sender: currentUser, // Must be admin
  text: "We are organizing a hackathon this weekend!",
  imageURL: "https://example.com/banner.jpg"
);
```

**Marking as Read:**
To register to the system that a member has seen the announcement:

```dart
await communityService.markBoardPostSeen(
  postId: 'announcement_id',
  user: currentUser
);
```

### Administrative Operations

Community admins can set community rules or pin an important post to the top of the community.

```dart
// Update rules
await communityService.setRules(
  communityId: 'community_id',
  admin: currentUser,
  rules: "1. Be respectful.\n2. No spamming."
);

// Pin an announcement
await communityService.setPinnedPost(
  communityId: 'community_id',
  postId: 'announcement_id',
  admin: currentUser
);
```

### Live Listening

Just as in chats, you can also listen to changes in community data instantaneously. For example, when the community image changes or a new rule is added, you can update your interface instantly.

```dart
communityService.listenCommunity(
  user: currentUser,
  onCreated: (community) {
    print("You were added to a new community: ${community.name}");
  },
  onUpdated: (community) {
    print("Community info updated: ${community.name}");
  },
  onDeleted: (id) {
    print("Community deleted: $id");
  }
);
```

# 8. Social Media Feed

Zeytin allows you to create not only messaging but also a rich content social media feed similar to Instagram or Twitter. The `ZeytinSocial` service manages nested interactions such as sharing posts, liking, commenting, and even liking comments.

This structure is stored in a special box called **social** in the database and utilizes the advantages of the non-relational NoSQL structure to the fullest.

### Sharing a Post

When you create a post, this data is stored as a single document on the server. Images, files, or location information are part of this document.

```dart
final socialService = ZeytinSocial(zeytin);

final newPost = ZeytinSocialModel(
  user: currentUser,
  text: "Developing with Zeytin is very enjoyable!",
  category: "Software",
  images: ["https://example.com/image1.jpg"],
  // If date is not assigned automatically in model, you can provide it yourself
  // createdAt can be managed on backend or kept inside moreData
);

final response = await socialService.createPost(postModel: newPost);

if (response.isSuccess) {
  print("Post shared!");
}
```

### Like Mechanism

Zeytin keeps like operations as arrays instead of relational tables. When a user likes a post, you call the `addLike` method. The server finds the relevant post and updates the document by adding the user's identity to the `likes` list. Thanks to this method, you don't need to send a second query asking "who liked this" when fetching a post.

```dart
// Like the post
await socialService.addLike(
  user: currentUser,
  postID: "post_id"
);

// Remove like
await socialService.removeLike(
  user: currentUser,
  postID: "post_id"
);
```

### Comments and Nested Interaction

In the Zeytin architecture, comments are stored directly inside the post, not in a separate table. This design choice maximizes performance because when you scroll through the feed, you don't have to fetch comments separately for each post. As soon as you fetch the post, the comments come along with it.

**Commenting:**

```dart
final comment = ZeytinSocialCommentsModel(
  user: currentUser,
  text: "Looks great!",
  postID: "post_id"
);

await socialService.addComment(
  comment: comment,
  postID: "post_id"
);
```

**Liking a Comment:**
The system supports liking not just posts but also comments.

```dart
await socialService.addCommentLike(
  user: currentUser,
  postID: "post_id",
  commentID: "comment_id"
);
```

### Fetching the Feed

You can use the `getAllPost` method to fetch the entire social media feed. This method brings all posts in the database, packaged together with the images, likes, and comments inside them.

```dart
final posts = await socialService.getAllPost();

for (var post in posts) {
  print("${post.user?.displayName}: ${post.text}");
  print("Like Count: ${post.likes?.length}");
}
```

# 9. E-Commerce and Store

Zeytin offers tools to transform your application into a full-fledged marketplace. Thanks to this module, your users can create their own stores, list their products, and track stock. Although the database structure is kept in two separate boxes as stores and products, the data talks to each other thanks to relational links.

### Creating a Store

The foundation of an e-commerce system is seller profiles. With the `ZeytinStore` service, you can create a business profile belonging to a user.

```dart
final storeService = ZeytinStore(zeytin);

final newStore = ZeytinStoreModel(
  id: '', // Automatically created
  name: "Techno Shop",
  description: "The newest technological products are here.",
  owners: [currentUser], // Store owners
  isVerified: true,
  rating: 5.0,
  createdAt: DateTime.now()
);

final response = await storeService.createStore(storeModel: newStore);

if (response.isSuccess) {
  print("Store opened, good luck with business!");
}
```

### Product Management

After the store is created, it is time to fill the shelves. The `ZeytinProducts` service handles product addition, update, and stock management operations. Every product is linked to the created store via the `storeId` field.

```dart
final productService = ZeytinProducts(zeytin);

final newProduct = ZeytinProductModel(
  id: '',
  storeId: 'store_id', // Which store it belongs to
  title: "Wireless Headphones",
  description: "Features noise cancellation.",
  price: 1500.0,
  discountedPrice: 1250.0, // Discounted price
  stock: 100,
  images: ["https://example.com/headphones.jpg"],
  category: "Electronics"
);

await productService.createProduct(productModel: newProduct);
```

### Product Interactions and Comments

Customers can like products or read comments before purchasing. Comments are stored as a list embedded inside the product data for performance. Thus, when you enter a product detail page, you do not need to send an extra query to fetch comments separately.

**Adding a Comment:**

```dart
final comment = ZeytinProductCommentModel(
  user: currentUser,
  text: "Sound quality is tremendous, I recommend it.",
  rating: 5.0
);

await productService.addComment(
  comment: comment,
  productID: "product_id"
);
```

**Like Operations:**

```dart
// Add product to favorites
await productService.addLike(
  user: currentUser,
  productID: "product_id"
);
```

### View Counter

A simple view counter is available to measure the popularity of products. You can increase the counter by calling this method every time a user enters the product details.

```dart
await productService.addView(productID: "product_id");
```

### Store and Product Listing

You can use standard fetch methods to list all stores or products.

```dart
// Get all products
final products = await productService.getAllProducts();

// Get all stores
final stores = await storeService.getAllStores();
```

# 10. Forum and Discussion

Beyond instant messaging and social media feeds, Zeytin includes a powerful forum engine for structured information sharing. The `ZeytinForum` service manages the hierarchy of categories, discussion threads, and replies (entries) written to these threads.

In the database structure, this module uses the `forum_categories` and `forum_threads` boxes. Replies are stored as a list embedded directly inside the relevant thread to ensure performance increases.

### Managing Categories

Categories form the skeleton of your forum. When creating a category, you can give it a title, description, and sorting priority.

```dart
final forumService = ZeytinForum(zeytin);

// Create a new category
await forumService.createCategory(
  categoryModel: ZeytinForumCategoryModel(
    id: '', // Automatically created
    title: 'Flutter Questions',
    description: 'Technical questions about Flutter go here.',
    order: 1,
    isActive: true
  )
);
```

### Opening a Topic (Thread)

When users want to start a discussion under a category, they use the `createThread` method. A topic thread can contain tags, content, and optional images.

```dart
await forumService.createThread(
  threadModel: ZeytinForumThreadModel(
    id: '',
    categoryId: 'category_id',
    user: currentUser,
    title: 'State Management Recommendation',
    content: 'Which method do you recommend for large projects?',
    tags: ['flutter', 'state-management', 'riverpod'],
    createdAt: DateTime.now()
  )
);
```

### Writing a Reply (Entry)

When a reply is written to a topic, the system does not add this reply as a separate document but adds it to the `entries` list of the relevant topic. Thanks to this method, when you open a topic, you do not have to query hundreds of replies one by one; they all come at once.

```dart
final newEntry = ZeytinForumEntryModel(
  id: '',
  threadId: 'topic_id',
  user: currentUser,
  text: 'I recommend using Riverpod, it is quite flexible.'
);

await forumService.addEntry(
  entry: newEntry,
  threadId: 'topic_id'
);
```

### Interactions

Users can like both the main topic and the sub-replies. Zeytin manages these operations with atomic updates.

```dart
// Like the topic
await forumService.addThreadLike(
  user: currentUser,
  threadId: 'topic_id'
);

// Like a reply
await forumService.addEntryLike(
  user: currentUser,
  threadId: 'topic_id',
  entryId: 'reply_id'
);
```

### Moderation Tools

Special tools are available for admins to maintain forum order.

**Locking the Topic:**
If the discussion has strayed from its purpose, you can prevent new replies by locking the topic.

```dart
await forumService.toggleThreadLock(
  threadId: 'topic_id',
  isLocked: true
);
```

**Pinning:**
You can use the pinning feature to keep important announcements at the top of the category.

```dart
await forumService.toggleThreadPin(
  threadId: 'topic_id',
  isPinned: true
);
```

**Marking as Resolved:**
If a question has been answered, you can change the topic status to resolved.

```dart
await forumService.toggleThreadResolve(
  threadId: 'topic_id',
  isResolved: true
);
```

# 11. Library and Book

Zeytin offers a specialized structure for you to create digital reading platforms similar to Wattpad or Kindle, not just social media or e-commerce. The `ZeytinLibrary` service controls the management of books, arrangement of chapters, and reader interactions.

In this architecture, we followed a hybrid data storage method for performance. While book metadata and comments stay in a single document, chapters containing long texts are stored in a separate box.

### Creating a Book

To add a work to the library, you use the `ZeytinBookModel` object. This model has detailed fields like ISBN number, author information, publisher, and stock quantity.

```dart
final libraryService = ZeytinLibrary(zeytin);

final newBook = ZeytinBookModel(
  id: '', // System assigns automatically
  isbn: "978-3-16-148410-0",
  title: "The Art of Dart Programming",
  subtitle: "From Zero to Advanced Level",
  authors: [currentUser],
  publisher: "Zeytin Publishing",
  price: 150.0,
  pageCount: 340,
  likes: [],
  categories: ["Software", "Education"]
);

final response = await libraryService.createBook(bookModel: newBook);

if (response.isSuccess) {
  print("The book has taken its place on the shelves.");
}
```

### Chapter Management

Keeping the entire book content in a single data piece can slow down mobile devices. Therefore, Zeytin stores chapters in a separate box named `chapters` and links them to the main book via `bookId`. Thus, when the user lists the book, they don't have to download thousands of pages of text; they only fetch the relevant chapter when they start reading.

**Adding a Chapter:**

```dart
final newChapter = ZeytinChapterModel(
  id: '',
  bookId: "book_id",
  title: "Chapter 1: Variables",
  content: "To define variables in Dart language...",
  order: 1, // Sorting index
  publishedDate: DateTime.now()
);

await libraryService.addChapter(chapter: newChapter);
```

**Listing Chapters:**
You can use the following method to create a book's table of contents. The system returns a list sorted by the `order` value.

```dart
final chapters = await libraryService.getBookChapters(bookID: "book_id");
```

### Reader Interactions

Readers can like books or comment on them. Since comments will not cause performance loss unlike chapters, they are stored in the `moreData` field directly inside the book data. This way, when you open the book detail page, the comments arrive ready.

**Like Operations:**

```dart
await libraryService.addLike(
  user: currentUser,
  bookID: "book_id"
);
```

**Commenting:**

```dart
final comment = ZeytinBookCommentModel(
  user: currentUser,
  text: "Great resource, explained very fluently.",
  bookID: "book_id"
);

await libraryService.addComment(
  comment: comment,
  bookID: "book_id"
);
```

### Search

A special search function is available for users to quickly find the book they are looking for by ISBN number. This function performs a prefix search on the `isbn` field in the database.

```dart
final results = await libraryService.searchByISBN("978-3");

for (var book in results) {
  print(book.title);
}
```

### Listing All Books

You can use the `getAllBooks` method to fetch the entire inventory in the library. This operation retrieves the author information, like counts, and basic data of each book but does not fetch the chapter contents. This keeps the list scrolling performance high.

```dart
final allBooks = await libraryService.getAllBooks();
```

# 12. Live Call - Livekit

Zeytin offers the `ZeytinCall` service for you to add audio and video calling features of Zoom or Discord quality to your application. This service uses the powerful LiveKit infrastructure in the background but passes all authentication and room management processes through Zeytin's own secure tunnel.

When you send a request to join a room, the Zeytin client first goes to the main server and asks for encrypted permission. The server checks the user's authority, generates a valid digital key for that moment, and delivers it to the client. The client connects securely to the media server with this key.

### Starting a Call

To join a room or start a new room, you use the `joinRoom` method. If the room name does not exist on the server, it is automatically created.

```dart
final callService = ZeytinCall(zeytin);

final response = await callService.joinRoom(
  roomName: "Software Team Meeting",
  user: currentUser,
  config: ZeytinCallConfig(
    audioEnabled: true,  // Start with microphone on
    videoEnabled: false, // Start with camera off
    speakerEnabled: true // Use speaker
  )
);

if (response.isSuccess) {
  print("Secure connection to the room established.");
}
```

### Listening to Participants and Status

During the call, it is necessary to track instantly who entered the room, who left, or who is talking. Zeytin presents these complex events as a simplified list with the `listenParticipants` method.

```dart
// Listen to participant list
callService.listenParticipants((participants) {
  for (var p in participants) {
    print("${p.user.displayName}");
    if (p.isTalking) {
      print("Is talking right now...");
    }
    if (p.isVideoEnabled) {
      // Show participant's video
      // VideoTrackRenderer(p.rawParticipant.videoTrackPublications.first.track)
    }
  }
});

// Listen to connection status (Connected, Disconnected, Reconnecting)
callService.listenStatus((status) {
  print("Status: $status");
});
```

### Media Controls

You can use the following methods to mute the microphone, turn on the camera, or start screen sharing during the call. These commands work on the currently active room.

```dart
// Toggle microphone on/off
await callService.toggleMicrophone(true);

// Toggle camera on/off
await callService.toggleCamera(false);

// Start/stop screen sharing
await callService.toggleScreenShare(true);

// Switch between speakerphone and earpiece (For mobile)
await callService.toggleSpeakerphone(true);
```

### Device Management

If the user has multiple cameras or microphones, access is provided to the `Hardware` interface to switch between them.

```dart
// List available cameras
final cameras = await callService.getVideoInputs();

// Select a specific camera
await callService.selectVideoInput(cameras.last);
```

### Leaving the Room

To end the call and free up resources, it is sufficient to call the `dispose` or `leaveRoom` method.

```dart
callService.leaveRoom();
```

# 13. Notification Service

The most important vein keeping user interaction alive in modern applications is the notification system. Zeytin offers a database-based, persistent, and real-time notification infrastructure without needing to deal with external services. This service is designed to manage not just "push" notifications, but also the notification history seen when the "Bell" icon inside the application is clicked or campaign announcements that suddenly pop up on the screen.

The `ZeytinNotificationService` class is at the center of these operations and works with a high-performance indexing logic.

### Sending Notifications

When you send a notification, the Zeytin server performs two operations in the background. First, it saves the notification data to the `notifications` box. Immediately after, it goes to the `my_notifications` index in the target users' profiles and adds the identity of this new notification. Thanks to this method, even if a notification is sent to millions of users, the database does not bloat, and queries do not slow down.

```dart
final notificationService = ZeytinNotificationService(zeytin);

await notificationService.sendNotification(
  title: "New Follower",
  description: "Ahmet started following you.",
  targetUserIds: [targetUser.uid], // People who will receive the notification
  type: "follow", // Notification type
  media: [
    ZeytinNotificationMediaModel(
      url: "https://example.com/profile.jpg",
      type: ZeytinNotificationMediaType.small
    )
  ]
);
```

### In-App Notifications

Sometimes, instead of a persistent notification list, you want to show an announcement or campaign that appears the moment the user opens the application. The `sendInAppNotification` method is customized for this scenario. These notifications stay in the "pending" list until seen by the user.

```dart
await notificationService.sendInAppNotification(
  title: "Big Sale!",
  description: "50% discount only for today.",
  tag: "promo_summer_2024", // Campaign tag
  targetUserIds: allUserIds,
  moreData: {'coupon': 'SUMMER50'}
);
```

### Listing Notifications

When fetching a user's notifications, the system does not scan the entire database. It looks directly at the user's `my_notifications` index and brings the details of only the notifications belonging to that user. Ready-made time filters like the last hour, last day, or last month are available within the service.

```dart
// Get notifications from the last 24 hours
final dailyNotifications = await notificationService.getLastDayNotifications(
  currentUser.uid
);

// Get pending in-app announcements (Ideal for showing modals)
final popups = await notificationService.getPendingInAppNotifications(
  currentUser.uid
);

if (popups.isNotEmpty) {
  print("Announcement to show: ${popups.first.title}");
}
```

### Marking as Seen

When a user sees or clicks a notification, the system needs to know this. The `markAsSeen` method adds the user's identity to the `seenBy` list of the relevant notification. This way, you avoid showing the same notification to the user over and over again.

```dart
await notificationService.markAsSeen(
  notificationId: "notification_id",
  userId: currentUser.uid
);
```

### Deleting Notifications

If a notification has lost its validity or was deleted by the user, you can completely remove it from the database with the `deleteNotification` method.

```dart
await notificationService.deleteNotification(
  notificationId: "notification_id"
);
```
