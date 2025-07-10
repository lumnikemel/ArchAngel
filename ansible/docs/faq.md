# Why are aren't you using native ZFS encryption?
- Native ZFS encryption still has several bugs open, some of which can cause data-loss. While these may not be gamechanging, the next point is.
- The performance of native encryption is significantly slower on reads. DM-Crypt performs much better in this regard.
- DM-Crypt with LUKS is a much more mature technology, supports more flexibility, like key-slots, TPM, etc.

# 
