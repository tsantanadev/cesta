# Cesta

A mobile grocery shopping list app where people build Lists, share them with others, and check Items off while shopping.

## Language

### People and access

**User**:
A person with a Cesta account, identified by their email address.
_Avoid_: Account, customer, profile, username

**Member**:
A User who has access to a specific List, with exactly one Role on it.
_Avoid_: Collaborator, participant, sharee

**Role**:
The level of access a Member has on a List: either Owner or Editor.
_Avoid_: Permission, access level

**Owner**:
The Role held by the User who created the List; it can delete the List, invite and remove Editors, and manage Share links. Each List has exactly one Owner; ownership never changes and the Owner cannot leave the List.
_Avoid_: Admin, creator

**Editor**:
The Role that can add, edit, remove, check and uncheck Items on a List, and leave it at any time.
_Avoid_: Contributor, collaborator

**Invitation**:
A pending offer, addressed to an email address, to become an Editor of a List; it takes effect only when the recipient accepts it. It expires 14 days after it is sent. The Owner still sees an expired one, so they know who never joined, until they cancel it or invite that address again.
_Avoid_: Invite request, share request

**Share link**:
A URL that lets any signed-in User who opens it become an Editor of a List, until it expires or the Owner revokes it. It can be passed along through any channel (messaging apps, email, a Share QR code).
_Avoid_: Invite link, public link

**Share QR code**:
A scannable rendering of a Share link, shown so someone nearby can join a List.
_Avoid_: Join code, invite QR

### Lists and items

**List**:
A named collection of Items that a group of Members shops from.
_Avoid_: Shopping list, cart, basket

**Recently deleted**:
The Lists an Owner deleted and can still restore, shown only to that Owner. A deleted List disappears for every Member at once and comes back for all of them when restored.
_Avoid_: Trash, bin, archive

**Restore window**:
The 30 days after deletion during which the Owner can restore a List from Recently deleted. Once it has passed, the List is gone for good.
_Avoid_: Grace period, retention period

**Purge**:
The daily job that removes for good, with their Memberships, the Lists whose Restore window has passed.
_Avoid_: Cleanup, hard delete

**Item**:
One entry on a List representing something to buy.
_Avoid_: Product, entry, line

**Checked Item**:
An Item marked as bought; it stays visible, crossed out at the bottom of the List, until cleared. Items not yet checked are the ones "to buy"; Checked Items are "in the basket".
_Avoid_: Done item, completed item, purchased item

**Clear checked**:
The action that removes all Checked Items from a List and records them in Item history.
_Avoid_: Archive, reset

**Item history**:
The record of Items that were bought (cleared after being checked) on a List.
_Avoid_: Purchase log, past items

**Matches**:
What Add items offers as the Member types: first the List's Items (to buy, then In the basket) whose names contain what was typed, ignoring case and accents, highlighted so the Member opens the Item already there instead of adding a duplicate; then the names from the List's Item history that match and aren't already on the List.
_Avoid_: Suggestions, search results, autocomplete

**Bought before**:
What Add items offers before anything is typed: the most recent distinct names from the List's Item history that aren't already on the List. Tapping one adds it to the List again, as it was last bought.
_Avoid_: Past items, recent items, favourites

**Undo window**:
The few seconds after an Item is added or removed during which a Toast offers Undo. A removal reaches the other Members only once the Undo window has closed, so undoing it changes nothing for them.
_Avoid_: Grace period, undo timeout

### Future

**Shopping mode**:
A focused view used inside the store, where Items are checked by scanning a barcode and a price is recorded.
_Avoid_: Store mode, checkout

**Product**:
A real-world thing that can be bought (e.g. a specific brand and size of milk), with its own barcode, category and price history; an Item may refer to one.
_Avoid_: Item, article, SKU
