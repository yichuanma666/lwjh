import threading
import time
from collections import deque
from typing import Deque


class SimpleRateLimiter:
    """
    简单的令牌桶/滑动窗口限速器。

    参数:
        max_calls: 时间窗口内最大请求数量
        period: 时间窗口长度（秒）
    """

    def __init__(self, max_calls: int, period: float):
        self.max_calls = max_calls
        self.period = period
        self._lock = threading.Lock()
        self._calls: Deque[float] = deque()

    def acquire(self) -> None:
        """
        当超出速率限制时阻塞，直到可以继续发送请求。
        """
        with self._lock:
            now = time.time()
            # 移除过期的时间戳
            while self._calls and self._calls[0] <= now - self.period:
                self._calls.popleft()

            if len(self._calls) < self.max_calls:
                self._calls.append(now)
                return

            # 需要等待到最早的一个请求过期
            wait_time = self.period - (now - self._calls[0])

        if wait_time > 0:
            time.sleep(wait_time)
        # 递归调用以更新队列
        self.acquire()


