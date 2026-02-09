from django.apps import AppConfig


class BlockchainConfig(AppConfig):
    default_auto_field = 'django.db.models.BigAutoField'
    name = 'blockchain'
    
    def ready(self):
        """Import signal handlers when app is ready"""
        import blockchain.signals  # noqa
