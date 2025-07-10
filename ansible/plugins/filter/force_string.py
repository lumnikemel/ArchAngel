class FilterModule(object):
    def filters(self):
        return {
            'force_string': self.force_string
        }

    def force_string(self, value):
        return str(value)
