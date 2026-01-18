# Test Suite Password Configuration

## Password File

The test suite uses a password file to avoid manual password entry:

- **File:** `test-password.txt`
- **Password:** ``
- **Permissions:** `600` (read-only for owner)

## Usage

All test scripts automatically read the password from `test-password.txt`:

```bash
# Test scripts will automatically use password from file
./test-ssh-after-boot.sh
./test-ssh.sh
./complete_test_suite.sh
```

## Password Helper

A helper function is available in `test-password-helper.sh`:

```bash
source test-password-helper.sh
PASSWORD=$(get_test_password)
```

## Build Script Integration

The build script (`imgbuild/moode-cfg/stage3_03-ghettoblaster-custom_00-run-chroot.sh`) also reads from the password file during image creation.

If the password file is available in the build workspace, it will be used. Otherwise, it defaults to ``.

## Changing the Password

To change the password:

1. Edit `test-password.txt`:
   ```bash
   echo "NEW_PASSWORD" > test-password.txt
   chmod 600 test-password.txt
   ```

2. All test scripts will automatically use the new password.

## Security

- The password file has restricted permissions (600)
- It should not be committed to version control
- Consider adding to `.gitignore` if needed

