/// Navigation payload for the chat thread sheet.
///
/// A thread can be entered two ways per the API ("Two ways in" — either
/// already knowing the [conversationId] (tapping an inbox row) or only an
/// [orderId] (an order-tracking screen's "Chat" button, which must resolve
/// the thread via `GET orders/:id/conversation` first). Exactly one of the
/// two must be provided. [peerName] is an optional best-effort title shown
/// while the real conversation is still loading.
///
/// [peerPhone] is never returned by the chat API itself (participants carry
/// no phone field) — it's only ever known when the caller already had it
/// locally (an order's cached `driverPhone`), and drives the sheet's
/// native-dialer "Call" affordance. `null` simply hides that button.
class ChatThreadArgs {
  const ChatThreadArgs({
    this.conversationId,
    this.orderId,
    this.peerName,
    this.peerPhone,
  }) : assert(
         conversationId != null || orderId != null,
         'Provide a conversationId or an orderId',
       );

  final String? conversationId;
  final String? orderId;
  final String? peerName;
  final String? peerPhone;
}
