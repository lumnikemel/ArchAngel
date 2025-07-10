# from ansible.plugins.connection.ssh import Connection as SSHConnection

# class Connection(SSHConnection):
#     transport = 'ssh_arch_chroot'  # Define the transport name

#     def __init__(self, *args, **kwargs):
#         super(Connection, self).__init__(*args, **kwargs)
#         # Initialize or override any required settings here

#     def exec_command(self, cmd, in_data=None, sudoable=True):
#         # Ensure the chroot path is correctly specified
#         chroot_path = "/mnt"
#         chroot_cmd = f"arch-chroot {chroot_path} {cmd}"
#         return super(Connection, self).exec_command(chroot_cmd, in_data, sudoable)


# from ansible.plugins.connection.ssh import Connection as SSHConnection

# class Connection(SSHConnection):
#     transport = 'ssh_arch_chroot'  # Define the transport name

#     def __init__(self, play_context, new_stdin, *args, **kwargs):
#         super(Connection, self).__init__(play_context, new_stdin, *args, **kwargs)
#         # Initialize or override any required settings here

#     def _connect(self):
#         # Call the parent's _connect method to establish the SSH connection
#         super(Connection, self)._connect()

#         # Set the host and port settings for the custom connection
#         self.host = self._play_context.remote_addr
#         self.port = self._play_context.port or 22

#     def exec_command(self, cmd, in_data=None, sudoable=True):
#         # Ensure the chroot path is correctly specified
#         chroot_path = "/mnt"
#         chroot_cmd = f"arch-chroot {chroot_path} {cmd}"
#         return super(Connection, self).exec_command(chroot_cmd, in_data, sudoable)
    

from ansible.plugins.connection.ssh import Connection as SSHConnection
from ansible.plugins.connection import ConnectionBase

class Connection(SSHConnection):
    transport = 'ssh_arch_chroot'  # Define the transport name

    def __init__(self, play_context, new_stdin, *args, **kwargs):
        super(Connection, self).__init__(play_context, new_stdin, *args, **kwargs)
        # Initialize or override any required settings here

    def _connect(self):
        # Call the parent's _connect method to establish the SSH connection
        super(Connection, self)._connect()

        # Set the host and port settings for the custom connection
        self.host = self._play_context.remote_addr
        self.port = self._play_context.port or 22

    def exec_command(self, cmd, in_data=None, sudoable=True):
        # Ensure the chroot path is correctly specified
        chroot_path = "/mnt"
        chroot_cmd = f"arch-chroot {chroot_path} {cmd}"
        return super(Connection, self).exec_command(chroot_cmd, in_data, sudoable)

    def _override_host(self):
        # Override the host setting with the value from play_context
        self.host = self._play_context.remote_addr

    def _override_port(self):
        # Override the port setting with the value from play_context
        self.port = self._play_context.port or 22

    def _connect_uncached(self):
        # Call the overridden _override_host and _override_port methods
        self._override_host()
        self._override_port()
        return super(Connection, self)._connect_uncached()