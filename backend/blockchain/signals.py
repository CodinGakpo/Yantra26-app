"""
Django Signals for Blockchain Integration

Signals connect complaint lifecycle events to blockchain writes.

Why signals?
- Decoupling: Blockchain logic doesn't pollute main app code
- Flexibility: Easy to enable/disable blockchain features
- Async-friendly: Can dispatch to Celery tasks

Important: These signals should trigger async tasks in production
to avoid blocking HTTP responses.
"""

import logging
from django.db.models.signals import post_save, pre_save
from django.dispatch import receiver
from django.conf import settings

logger = logging.getLogger(__name__)


# ============ Complaint Lifecycle Signals ============

@receiver(post_save, sender='report.IssueReport')
def log_complaint_created(sender, instance, created, **kwargs):
    """
    Log complaint creation to blockchain.
    
    Triggered when: New IssueReport is created
    Blockchain event: CREATED
    """
    if not created:
        return
    
    if not getattr(settings, 'BLOCKCHAIN_ENABLED', True):
        return
    
    try:
        from blockchain.utils import create_event_payload
        from blockchain.tasks import log_complaint_event_async
        
        # Create event payload
        payload = create_event_payload(
            complaint_id=instance.tracking_id,
            event_type='CREATED',
            data={
                'issue_title': instance.issue_title,
                'category': instance.category,
                'location': {
                    'lat': str(instance.location_lat) if instance.location_lat else None,
                    'lng': str(instance.location_lng) if instance.location_lng else None,
                },
                'status': instance.status,
            },
            actor=instance.reporter_email or 'anonymous'
        )
        
        # Dispatch async task
        log_complaint_event_async.delay(
            complaint_id=instance.tracking_id,
            event_type='CREATED',
            payload=payload
        )
        
        logger.info(f"Dispatched blockchain event: {instance.tracking_id} - CREATED")
        
    except Exception as e:
        logger.error(f"Failed to dispatch blockchain event: {e}")


@receiver(post_save, sender='report.IssueReport')
def log_complaint_assigned(sender, instance, created, **kwargs):
    """
    Log complaint assignment to blockchain.
    
    Triggered when: allocated_to field is set
    Blockchain event: ASSIGNED
    """
    if created:
        return
    
    if not getattr(settings, 'BLOCKCHAIN_ENABLED', True):
        return
    
    # Check if allocated_to changed
    if instance.tracker.has_changed('allocated_to') and instance.allocated_to:
        try:
            from blockchain.utils import create_event_payload
            from blockchain.tasks import log_complaint_event_async, set_sla_deadline_async
            
            # Log assignment
            payload = create_event_payload(
                complaint_id=instance.tracking_id,
                event_type='ASSIGNED',
                data={
                    'assigned_to': instance.allocated_to,
                    'assigned_at': instance.tracker.changed().get('allocated_to'),
                },
                actor='system'
            )
            
            log_complaint_event_async.delay(
                complaint_id=instance.tracking_id,
                event_type='ASSIGNED',
                payload=payload
            )
            
            # Set SLA deadline (48 hours default)
            sla_hours = getattr(settings, 'COMPLAINT_SLA_HOURS', 48)
            set_sla_deadline_async.delay(
                complaint_id=instance.tracking_id,
                hours=sla_hours
            )
            
            logger.info(f"Dispatched blockchain events: {instance.tracking_id} - ASSIGNED + SLA")
            
        except Exception as e:
            logger.error(f"Failed to log assignment: {e}")


@receiver(post_save, sender='report.IssueReport')
def log_complaint_status_updated(sender, instance, created, **kwargs):
    """
    Log complaint status change to blockchain.
    
    Triggered when: status field changes
    Blockchain event: STATUS_UPDATED or RESOLVED
    """
    if created:
        return
    
    if not getattr(settings, 'BLOCKCHAIN_ENABLED', True):
        return
    
    # Check if status changed
    if instance.tracker.has_changed('status'):
        try:
            from blockchain.utils import create_event_payload
            from blockchain.tasks import log_complaint_event_async
            
            old_status = instance.tracker.previous('status')
            new_status = instance.status
            
            # Determine event type
            event_type = 'RESOLVED' if new_status == 'resolved' else 'STATUS_UPDATED'
            
            payload = create_event_payload(
                complaint_id=instance.tracking_id,
                event_type=event_type,
                data={
                    'old_status': old_status,
                    'new_status': new_status,
                },
                actor='system'
            )
            
            log_complaint_event_async.delay(
                complaint_id=instance.tracking_id,
                event_type=event_type,
                payload=payload
            )
            
            logger.info(f"Dispatched blockchain event: {instance.tracking_id} - {event_type}")
            
        except Exception as e:
            logger.error(f"Failed to log status update: {e}")


# ============ Evidence Upload Signal ============

def log_evidence_uploaded(complaint_id: str, file_path: str, file_hash: str, file_name: str = None):
    """
    Log evidence upload to blockchain.
    
    This is called manually from the evidence upload view.
    
    Args:
        complaint_id: Complaint identifier
        file_path: Local file path (relative to MEDIA_ROOT)
        file_hash: SHA-256 hash of file
        file_name: Optional original filename
    """
    if not getattr(settings, 'BLOCKCHAIN_ENABLED', True):
        return
    
    try:
        from blockchain.tasks import anchor_evidence_async
        
        anchor_evidence_async.delay(
            complaint_id=complaint_id,
            file_hash=file_hash,
            file_path=file_path,
            file_metadata={
                'name': file_name or file_path.split('/')[-1],
                'path': file_path
            }
        )
        
        logger.info(f"Dispatched evidence anchoring: {complaint_id} - {file_path}")
        
    except Exception as e:
        logger.error(f"Failed to dispatch evidence anchoring: {e}")


# ============ Model Tracker Setup ============
# To track field changes, we need to add a tracker to the IssueReport model
# This requires installing django-model-utils

"""
Add to report/models.py:

from model_utils import FieldTracker

class IssueReport(models.Model):
    # ... existing fields ...
    
    # Add this at the end
    tracker = FieldTracker(fields=['allocated_to', 'status'])
"""
