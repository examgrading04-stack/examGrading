try:
    from backend.app.services.qr import *  # noqa: F403
except ModuleNotFoundError:
    from app.services.qr import *  # noqa: F403
