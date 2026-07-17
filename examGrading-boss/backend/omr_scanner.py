try:
    from backend.app.services.omr_scanner import *  # noqa: F403
except ModuleNotFoundError:
    from app.services.omr_scanner import *  # noqa: F403
