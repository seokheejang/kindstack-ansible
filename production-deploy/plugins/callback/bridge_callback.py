#!/usr/bin/env python3

import json
import os
import requests
from ansible.plugins.callback import CallbackBase
import logging

# 로깅 설정
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

class CallbackModule(CallbackBase):
    """
    Bridge 서버로 배포 상태를 전송하는 콜백 플러그인
    """
    CALLBACK_VERSION = 2.0
    CALLBACK_TYPE = 'notification'
    CALLBACK_NAME = 'bridge_callback'
    CALLBACK_NEEDS_WHITELIST = True

    def __init__(self):
        super(CallbackModule, self).__init__()
        self.bridge_url = os.getenv('BRIDGE_SERVER_URL', 'http://localhost:8080')
        self.deployment_id = os.getenv('DEPLOYMENT_ID')
        self.current_step = None
        
        # 태스크 이름과 배포 단계 매핑
        self.step_mapping = {
            'route53': ['route53', 'dns'],
            'load_balancer': ['lb', 'load_balancer', 'alb', 'elb'],
            'k8s_service': ['service', 'k8s_service', 'kubernetes_service'],
            'ingress': ['ingress', 'k8s_ingress'],
            'domain_mapping': ['domain', 'mapping', 'dns_mapping']
        }

    def _send_callback(self, step_name, status, message=""):
        """Bridge 서버로 콜백 전송"""
        if not self.deployment_id:
            logger.warning("DEPLOYMENT_ID가 설정되지 않았습니다.")
            return

        callback_data = {
            'deployment_id': int(self.deployment_id),
            'step_name': step_name,
            'status': status,
            'message': message
        }

        try:
            url = f"{self.bridge_url}/api/v1/infra/callback"
            response = requests.post(
                url,
                json=callback_data,
                headers={'Content-Type': 'application/json'},
                timeout=30
            )
            
            if response.status_code == 200:
                logger.info(f"콜백 전송 성공: {step_name} - {status}")
            else:
                logger.error(f"콜백 전송 실패: {response.status_code} - {response.text}")
                
        except Exception as e:
            logger.error(f"콜백 전송 중 오류: {str(e)}")

    def _get_step_from_task_name(self, task_name):
        """태스크 이름에서 배포 단계 추출"""
        task_name_lower = task_name.lower()
        
        for step, keywords in self.step_mapping.items():
            for keyword in keywords:
                if keyword in task_name_lower:
                    return step
        
        return None

    def v2_playbook_on_start(self, playbook):
        """플레이북 시작"""
        logger.info(f"플레이북 시작: {playbook._file_name}")

    def v2_playbook_on_task_start(self, task, is_conditional):
        """태스크 시작"""
        task_name = task.get_name()
        step = self._get_step_from_task_name(task_name)
        
        if step:
            self.current_step = step
            self._send_callback(step, 'running', f"태스크 시작: {task_name}")
            logger.info(f"태스크 시작: {task_name} (단계: {step})")

    def v2_runner_on_ok(self, result):
        """태스크 성공"""
        if self.current_step:
            task_name = result.task_name if hasattr(result, 'task_name') else result._task.get_name()
            self._send_callback(self.current_step, 'completed', f"태스크 완료: {task_name}")
            logger.info(f"태스크 성공: {task_name}")

    def v2_runner_on_failed(self, result, ignore_errors=False):
        """태스크 실패"""
        if self.current_step:
            task_name = result.task_name if hasattr(result, 'task_name') else result._task.get_name()
            error_msg = result._result.get('msg', '알 수 없는 오류')
            self._send_callback(self.current_step, 'failed', f"태스크 실패: {task_name} - {error_msg}")
            logger.error(f"태스크 실패: {task_name} - {error_msg}")

    def v2_runner_on_unreachable(self, result):
        """호스트 접근 불가"""
        if self.current_step:
            task_name = result.task_name if hasattr(result, 'task_name') else result._task.get_name()
            self._send_callback(self.current_step, 'failed', f"호스트 접근 불가: {task_name}")
            logger.error(f"호스트 접근 불가: {task_name}")

    def v2_playbook_on_stats(self, stats):
        """플레이북 완료 통계"""
        logger.info("플레이북 실행 완료")
        
        # 전체 실행 결과 요약
        for host in stats.processed:
            summary = stats.summarize(host)
            if summary['failures'] > 0 or summary['unreachable'] > 0:
                logger.error(f"호스트 {host}에서 실패 발생: {summary}")
            else:
                logger.info(f"호스트 {host} 실행 성공: {summary}")
