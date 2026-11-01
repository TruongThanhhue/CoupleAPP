# Partner connection

## User job

See and safely share a personal connection code, send a partner invitation by code, and explicitly accept or decline received invitations.

## Flow

1. Registration generates one opaque, public `CPL-XXXXXXXX` code per account.
2. A user enters their partner's code and submits an invitation.
3. The recipient sees the sender's display name and chooses **Chấp nhận** or **Từ chối**.
4. Only acceptance links the two accounts. A linked account cannot send or accept another invitation.
5. The sender can see and cancel a pending outgoing invitation.

## UI states

- Loading: profile and pending invitations are loading.
- Unlinked: own code, copy affordance, code field, send action.
- Pending incoming: sender name with accept/decline actions.
- Pending outgoing: recipient name, waiting status, and cancel action.
- Connected: partner name and clear connected status.
- Error: server-provided safe message under the affected action.

## Privacy and accessibility

- The public connection code is not a database UUID and does not expose email.
- A code sender cannot establish a relationship unilaterally.
- Copy and submit controls have textual labels/tooltips; code is selectable and works with large text.
- No location, cycle, or other sensitive data is shared in this flow.
