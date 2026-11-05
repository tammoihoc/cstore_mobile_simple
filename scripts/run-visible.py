#!/usr/bin/env python3
"""Run a command with live output in a reusable Kitty window and private log files."""
import argparse
import collections
import errno
import fcntl
import os
from pathlib import Path
import pty
import select
import shutil
import signal
import subprocess
import sys
import time
from datetime import datetime

ROOT = Path(__file__).resolve().parents[1]
LOGS = ROOT / '.local' / 'visible-tests'
SESSION = LOGS / 'session.log'


def viewer():
    with (LOGS / 'viewer.lock').open('a') as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            return
        with SESSION.open() as stream:
            print('C-Store — log trực tiếp. Mỗi lượt có BẮT ĐẦU / KẾT THÚC.', flush=True)
            print(''.join(collections.deque(stream, maxlen=80)), end='', flush=True)
            while True:
                chunk = stream.read(8192)
                if chunk:
                    print(chunk, end='', flush=True)
                else:
                    time.sleep(0.1)


def viewer_running():
    with (LOGS / 'viewer.lock').open('a') as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
            return False
        except BlockingIOError:
            return True


def ensure_viewer():
    # Serialize startup so simultaneous commands do not open duplicate windows.
    with (LOGS / 'startup.lock').open('a') as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        if viewer_running():
            return
        kitty = shutil.which('kitty')
        if not kitty or not (os.getenv('DISPLAY') or os.getenv('WAYLAND_DISPLAY')):
            raise RuntimeError('Cần Kitty và phiên đồ họa để hiển thị log trước khi chạy.')
        with (LOGS / 'kitty.log').open('ab') as output:
            process = subprocess.Popen(
                [kitty, '--session', 'none', '--title', 'C-Store — Test logs',
                 sys.executable, str(Path(__file__).resolve()), '--viewer'],
                stdin=subprocess.DEVNULL, stdout=output, stderr=output,
                start_new_session=True)
        for _ in range(100):
            if viewer_running():
                return
            if process.poll() is not None:
                break
            time.sleep(0.1)
        if process.poll() is None:
            process.terminate()
        raise RuntimeError(f'Không mở được Kitty. Xem {LOGS / "kitty.log"}; lệnh chưa chạy.')


def open_chrome(url):
    chrome = next((path for name in ('google-chrome-stable', 'google-chrome', 'chromium',
                                    'chromium-browser') if (path := shutil.which(name))), None)
    if not chrome:
        raise RuntimeError('Không tìm thấy Chrome/Chromium; lệnh chưa chạy.')
    # Chrome uses the existing browser session when it is already running.
    with (LOGS / 'chrome.log').open('ab') as output:
        process = subprocess.Popen([chrome, url], stdin=subprocess.DEVNULL,
                                   stdout=output, stderr=output, start_new_session=True)
    time.sleep(0.5)
    if process.poll() not in (None, 0):
        raise RuntimeError(f'Không mở được Chrome. Xem {LOGS / "chrome.log"}; lệnh chưa chạy.')


def run(command, label):
    filename = datetime.now().strftime('%Y%m%d-%H%M%S') + f'-{os.getpid()}.log'
    with SESSION.open('ab', buffering=0) as session, (LOGS / filename).open('ab', buffering=0) as log:
        def emit(data):
            session.write(data)
            log.write(data)
            sys.stdout.buffer.write(data)
            sys.stdout.buffer.flush()

        def status(message):
            emit(f'\n[{datetime.now().astimezone().isoformat(timespec="seconds")}] {message}\n'.encode())

        status(f'BẮT ĐẦU: {label} | thư mục: {Path.cwd()} | log: {LOGS / filename}')
        master, slave = pty.openpty()
        try:
            process = subprocess.Popen(command, stdin=slave, stdout=slave, stderr=slave,
                                       start_new_session=True,
                                       env={**os.environ, 'PYTHONUNBUFFERED': '1'})
        except OSError as error:
            os.close(master)
            status(f'KẾT THÚC: {label} | không chạy được lệnh: {error} | mã thoát: 127')
            return 127
        finally:
            os.close(slave)
        old_handlers = {}

        def forward(signum, _frame):
            if process.poll() is None:
                try:
                    os.killpg(process.pid, signum)
                except ProcessLookupError:
                    pass

        for signum in (signal.SIGINT, signal.SIGTERM):
            old_handlers[signum] = signal.signal(signum, forward)
        try:
            inputs = [master] + ([sys.stdin.fileno()] if sys.stdin.isatty() else [])
            while True:
                ready, _, _ = select.select(inputs, [], [], 0.2)
                if master in ready:
                    try:
                        data = os.read(master, 65536)
                    except OSError as error:
                        if error.errno != errno.EIO:
                            raise
                        break
                    if not data:
                        break
                    emit(data)
                if len(inputs) > 1 and inputs[1] in ready:
                    data = os.read(inputs[1], 4096)
                    if data:
                        os.write(master, data)
                    else:
                        inputs.pop()
            code = process.wait()
        finally:
            os.close(master)
            if process.poll() is None:
                os.killpg(process.pid, signal.SIGTERM)
                try:
                    process.wait(timeout=5)
                except subprocess.TimeoutExpired:
                    os.killpg(process.pid, signal.SIGKILL)
                    process.wait()
            for signum, handler in old_handlers.items():
                signal.signal(signum, handler)
        code = code if code >= 0 else 128 - code
        status(f'KẾT THÚC: {label} | mã thoát: {code}')
        return code


def main():
    parser = argparse.ArgumentParser(description=__doc__, epilog=(
        'Ví dụ: python3 scripts/run-visible.py --name "API test" '
        '--url http://127.0.0.1:8080/api/branches -- python3 scripts/test-live.py'))
    parser.add_argument('--name', help='Tên lượt chạy hiển thị trong log')
    parser.add_argument('--cwd', type=Path, help='Thư mục chạy lệnh, tính từ thư mục hiện tại')
    parser.add_argument('--url', help='Mở URL trong Chrome; dùng lại phiên Chrome đang mở')
    parser.add_argument('--viewer', action='store_true', help=argparse.SUPPRESS)
    parser.add_argument('command', nargs=argparse.REMAINDER)
    args = parser.parse_args()
    if args.viewer:
        viewer()
        return 0
    command = args.command[1:] if args.command[:1] == ['--'] else args.command
    if not command:
        parser.error('Cần lệnh sau --')
    if args.url and not args.url.startswith(('http://', 'https://', 'file://')):
        parser.error('--url phải bắt đầu bằng http://, https:// hoặc file://')
    if args.cwd:
        directory = args.cwd.resolve()
        if not directory.is_dir():
            parser.error(f'--cwd không phải thư mục hợp lệ: {directory}')
        os.chdir(directory)
    os.umask(0o077)
    LOGS.mkdir(parents=True, exist_ok=True, mode=0o700)
    SESSION.touch(mode=0o600, exist_ok=True)
    ensure_viewer()
    if args.url:
        open_chrome(args.url)
    return run(command, args.name or Path(command[0]).name)


if __name__ == '__main__':
    try:
        raise SystemExit(main())
    except (OSError, RuntimeError) as error:
        print(f'Lỗi: {error}', file=sys.stderr)
        raise SystemExit(1)
