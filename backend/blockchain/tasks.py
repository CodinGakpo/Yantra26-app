"""
Celery Tasks for Async Blockchain Operations

Why Celery?
- Blockchain writes are slow (10-60 seconds)
- Don't block HTTP responses
- Retry on failure
- Rate limiting and queuing

Setup:
1. pip install celery redis
2. Start Redis: redis-server
3. Start Celery worker: celery -A report_hub worker -l info
4. Start Celery beat (for periodic tasks): celery -A report_hub beat -l info
"""

import logging
from celery import shared_task
from django.conf import settings

logger = logging.getLogger(__name__)


@shared_task(bind=True, max_retries=3, default_retry_delay=60)
def log_complaint_event_async(self, complaint_id: str, event_type: str, payload: dict):
    """
    Async task to log complaint event to blockchain.
    
    Args:
        complaint_id: Complaint identifier
        event_type: Event type
        payload: Event payload to hash and log
    """
    try:
        from blockchain.services import get_blockchain_service
        
        service = get_blockchain_service()
        result = service.log_complaint_event(complaint_id, event_type, payload)
        
        if result:
            logger.info(f"✓ Blockchain event logged: {complaint_id} - {event_type}")
            return {
                'success': True,
                'tx_hash': result.tx_hash,
                'complaint_id': complaint_id,
                'event_type': event_type
            }
        else:
            raise Exception("Blockchain write failed")
            
    except Exception as e:
        logger.error(f"Blockchain event failed: {e}")
        
        # Retry with exponential backoff
        try:
            self.retry(exc=e, countdown=60 * (2 ** self.request.retries))
        except self.MaxRetriesExceededError:
            logger.error(f"Max retries exceeded for {complaint_id} - {event_type}")
            
        return {
            'success': False,
            'error': str(e),
            'complaint_id': complaint_id,
            'event_type': event_type
        }


@shared_task(bind=True, max_retries=3, default_retry_delay=60)
def anchor_evidence_async(
    self,
    complaint_id: str,
    file_hash: str,
    file_path: str,
    file_metadata: dict = None
):
    """
    Async task to anchor evidence hash on blockchain.
    
    Args:
        complaint_id: Complaint identifier
        file_hash: SHA-256 hash of file
        file_path: Local file path (relative to MEDIA_ROOT)
        file_metadata: Optional metadata dict
    """
    try:
        from blockchain.services import get_blockchain_service
        
        service = get_blockchain_service()
        result = service.anchor_evidence(
            complaint_id,
            file_hash,
            file_path,
            file_metadata
        )
        
        if result:
            logger.info(f"✓ Evidence anchored: {complaint_id} - {file_path}")
            return {
                'success': True,
                'tx_hash': result.tx_hash,
                'complaint_id': complaint_id,
                'file_path': file_path
            }
        else:
            raise Exception("Evidence anchoring failed")
            
    except Exception as e:
        logger.error(f"Evidence anchoring failed: {e}")
        
        try:
            self.retry(exc=e, countdown=60 * (2 ** self.request.retries))
        except self.MaxRetriesExceededError:
            logger.error(f"Max retries exceeded for evidence {file_path}")
            
        return {
            'success': False,
            'error': str(e),
            'complaint_id': complaint_id,
            'file_path': file_path
        }


@shared_task(bind=True, max_retries=3, default_retry_delay=60)
def set_sla_deadline_async(self, complaint_id: str, hours: int = 48):
    """
    Async task to set SLA deadline on blockchain.
    
    Args:
        complaint_id: Complaint identifier
        hours: Hours until deadline
    """
    try:
        from blockchain.services import get_blockchain_service
        
        service = get_blockchain_service()
        result = service.set_sla_deadline(complaint_id, hours)
        
        if result:
            logger.info(f"✓ SLA deadline set: {complaint_id} - {hours}h")
            return {
                'success': True,
                'complaint_id': complaint_id,
                'deadline_hours': hours
            }
        else:
            raise Exception("SLA deadline setting failed")
            
    except Exception as e:
        logger.error(f"SLA deadline setting failed: {e}")
        
        try:
            self.retry(exc=e, countdown=60 * (2 ** self.request.retries))
        except self.MaxRetriesExceededError:
            logger.error(f"Max retries exceeded for SLA {complaint_id}")
            
        return {
            'success': False,
            'error': str(e),
            'complaint_id': complaint_id
        }


@shared_task
def check_sla_violations():
    """
    Periodic task to check for SLA violations and escalate.
    
    Schedule this with Celery Beat:
    
    # In celery.py or settings.py
    from celery.schedules import crontab
    
    CELERY_BEAT_SCHEDULE = {
        'check-sla-violations': {
            'task': 'blockchain.tasks.check_sla_violations',
            'schedule': crontab(minute='*/15'),  # Every 15 minutes
        },
    }
    """
    try:
        from blockchain.models import SLATracker
        from blockchain.services import get_blockchain_service
        from django.utils import timezone
        import time
        
        service = get_blockchain_service()
        
        # Get non-escalated complaints nearing deadline
        current_timestamp = int(time.time())
        
        # Find complaints that might need escalation
        trackers = SLATracker.objects.filter(
            escalated=False,
            sla_deadline__lte=current_timestamp
        )[:50]  # Batch size
        
        if not trackers.exists():
            logger.info("No SLA violations found")
            return {'checked': 0, 'escalated': 0}
        
        complaint_ids = [t.complaint_id for t in trackers]
        
        # Batch check and escalate on blockchain
        escalated_count = service.batch_check_and_escalate(complaint_ids)
        
        logger.warning(f"SLA check complete: {len(complaint_ids)} checked, {escalated_count} escalated")
        
        # Send notifications for escalated complaints
        if escalated_count > 0:
            send_escalation_notifications.delay(complaint_ids[:escalated_count])
        
        return {
            'checked': len(complaint_ids),
            'escalated': escalated_count
        }
        
    except Exception as e:
        logger.error(f"SLA check task failed: {e}")
        return {'error': str(e)}


@shared_task
def send_escalation_notifications(complaint_ids: list):
    """
    Send notifications for escalated complaints.
    
    Args:
        complaint_ids: List of escalated complaint IDs
    """
    try:
        # Import your notification service
        # from notifications.service import send_escalation_alert
        
        for complaint_id in complaint_ids:
            # TODO: Implement your notification logic
            # - Email to admins
            # - SMS alerts
            # - Dashboard notifications
            # - Slack/Teams webhooks
            
            logger.warning(f"ESCALATION ALERT: {complaint_id}")
            
            # Example:
            # send_escalation_alert(complaint_id)
        
        return {'notified': len(complaint_ids)}
        
    except Exception as e:
        logger.error(f"Notification task failed: {e}")
        return {'error': str(e)}


@shared_task
def sync_blockchain_events():
    """
    Periodic task to sync blockchain events to database.
    
    This listens for events emitted by the smart contract and updates
    the local database accordingly.
    
    Schedule with Celery Beat every 5-10 minutes.
    """
    try:
        from blockchain.listeners import sync_events_from_blockchain
        
        result = sync_events_from_blockchain()
        
        logger.info(f"Blockchain sync: {result}")
        return result
        
    except Exception as e:
        logger.error(f"Blockchain sync failed: {e}")
        return {'error': str(e)}


@shared_task
def retry_failed_transactions():
    """
    Retry failed blockchain transactions.
    
    Schedule with Celery Beat periodically (e.g., hourly).
    """
    try:
        from blockchain.models import BlockchainTransaction
        from datetime import timedelta
        from django.utils import timezone
        
        # Get failed transactions from last 24 hours
        cutoff = timezone.now() - timedelta(hours=24)
        failed_txs = BlockchainTransaction.objects.filter(
            status='FAILED',
            timestamp__gte=cutoff
        )[:10]  # Limit retries
        
        retry_count = 0
        
        for tx in failed_txs:
            # Retry based on event type
            if tx.event_type in ['CREATED', 'ASSIGNED', 'STATUS_UPDATED', 'RESOLVED', 'ESCALATED']:
                log_complaint_event_async.delay(
                    tx.complaint_id,
                    tx.event_type,
                    tx.event_payload
                )
                retry_count += 1
        
        logger.info(f"Retried {retry_count} failed transactions")
        return {'retried': retry_count}
        
    except Exception as e:
        logger.error(f"Retry task failed: {e}")
        return {'error': str(e)}
