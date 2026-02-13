// enum AttachmentType {
//   meshRenderer,
// }

// class Attachment {
//   final AttachmentType type;

//   Attachment({
//     required this.type,
//   });
// }

// class Node {
//   String name;

//   final List<Node> children;
//   final List<Attachment> attachments;

//   Node({
//     required this.name,
//     required this.children,
//     required this.attachments,
//   });
// }

// final exampleNodeGraph = Node(
//   name: 'Root',
//   children: [
//     Node(
//       name: 'Robot',
//       children: [
//         Node(
//           name: 'Frame',
//           children: [
//             Node(
//               name: 'Battery',
//               children: [],
//               attachments: [
//                 Attachment(
//                   type: AttachmentType.meshRenderer,
//                 ),
//               ],
//             ),
//           ],
//           attachments: [
//             Attachment(
//               type: AttachmentType.meshRenderer,
//             ),
//           ],
//         ),
//         Node(
//           name: 'Tracks',
//           children: [],
//           attachments: [
//             Attachment(
//               type: AttachmentType.meshRenderer,
//             ),
//           ],
//         ),
//       ],
//       attachments: [],
//     ),
//   ],
//   attachments: [],
// );
