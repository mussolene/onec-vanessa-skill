#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import os
import shlex
import shutil
import subprocess
import sys
import tempfile
import zipfile
from datetime import datetime
from pathlib import Path
from typing import Any


SCRIPT_DIR = Path(__file__).resolve().parent
SKILL_ROOT = SCRIPT_DIR.parent
REPO_ROOT = SKILL_ROOT.parent


def load_env(path: Path) -> dict[str, str]:
    values: dict[str, str] = {}
    if not path.exists():
        return values

    for line in path.read_text(encoding="utf-8").splitlines():
        stripped = line.strip()
        if not stripped or stripped.startswith("#") or "=" not in stripped:
            continue
        key, value = stripped.split("=", 1)
        values[key.strip()] = value.strip()
    return values


def merge_env_template_file(target_path: Path, template_path: Path) -> None:
    if not target_path.exists() or not template_path.exists():
        return

    target_lines = target_path.read_text(encoding="utf-8").splitlines()
    existing_keys = {
        line.split("=", 1)[0].strip()
        for line in target_lines
        if line.strip() and not line.strip().startswith("#") and "=" in line
    }

    additions: list[str] = []
    for line in template_path.read_text(encoding="utf-8").splitlines():
        stripped = line.strip()
        if not stripped or stripped.startswith("#") or "=" not in stripped:
            continue
        key = line.split("=", 1)[0].strip()
        if key not in existing_keys:
            additions.append(line)
            existing_keys.add(key)

    if additions:
        separator = "" if not target_lines or target_lines[-1] == "" else "\n"
        target_path.write_text(
            "\n".join(target_lines) + separator + "# Added by bootstrap from current template\n" + "\n".join(additions) + "\n",
            encoding="utf-8",
        )


def get_setting(env_map: dict[str, str], name: str, default: str = "", required: bool = False) -> str:
    value = os.environ.get(name) or env_map.get(name) or default
    if required and not value:
        raise RuntimeError(f"Missing required setting: {name}")
    return value


def ensure_directory(path: Path) -> Path:
    path.mkdir(parents=True, exist_ok=True)
    return path


def new_run_context(category: str, name: str = "run") -> Path:
    root = ensure_directory(REPO_ROOT / "artifacts" / category)
    run_id = f"{datetime.now().strftime('%Y%m%d-%H%M%S-%f')}-{name}"
    return ensure_directory(root / run_id)


def save_text(path: Path, value: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(value, encoding="utf-8")


def save_json(path: Path, value: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def migrate_va_params_file(path: Path) -> None:
    if not path.exists():
        return

    try:
        config = json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return

    if not isinstance(config, dict):
        return

    changed = False
    legacy_output_prefix = "Каталог" + "Output"
    renamed_keys = {
        f"{legacy_output_prefix}Скриншоты": "КаталогВыгрузкиСкриншотов",
        f"{legacy_output_prefix}CucumberJson": "КаталогВыгрузкиCucumberJson",
        f"{legacy_output_prefix}AllureБазовый": "КаталогВыгрузки AllureБазовый",
    }
    for old_key, new_key in renamed_keys.items():
        if old_key in config:
            if new_key not in config:
                config[new_key] = config[old_key]
            del config[old_key]
            changed = True

    if "ПриравниватьPendingКFailed" not in config:
        config["ПриравниватьPendingКFailed"] = True
        changed = True

    screenshot_command = str(config.get("КомандаСделатьСкриншот", "") or "")
    uses_addin_screenshots = bool(config.get("ИспользоватьВнешнююКомпонентуДляСкриншотов"))
    if uses_addin_screenshots and not config.get("ИспользоватьКомпонентуVanessaExt"):
        config["ИспользоватьКомпонентуVanessaExt"] = True
        changed = True

    screenshots_enabled = bool(config.get("ДелатьСкриншотПриВозникновенииОшибки"))
    if screenshots_enabled and not screenshot_command and not uses_addin_screenshots:
        config["ДелатьСкриншотПриВозникновенииОшибки"] = False
        changed = True

    if changed:
        save_json(path, config)


def repo_path(value: str) -> Path:
    path = Path(value)
    return path if path.is_absolute() else (REPO_ROOT / path)


def format_command_line(file_path: str, arguments: list[str]) -> str:
    parts = [file_path, *arguments]
    return " ".join(shlex.quote(part) for part in parts)


def write_command_file(path: Path, file_path: str, arguments: list[str]) -> None:
    save_text(path, format_command_line(file_path, arguments))


def invoke_logged_command(file_path: str, arguments: list[str], stdout_path: Path, dry_run: bool) -> dict[str, Any]:
    if dry_run:
        save_text(stdout_path, "Dry-run. Command was not launched.\n")
        return {"exit_code": 0, "launched": False}

    completed = subprocess.run(
        [file_path, *arguments],
        stdout=subprocess.PIPE,
        stderr=subprocess.STDOUT,
        text=True,
        encoding="utf-8",
        errors="replace",
        cwd=str(REPO_ROOT),
        check=False,
    )
    save_text(stdout_path, completed.stdout)
    return {"exit_code": completed.returncode, "launched": True}


def resolve_loader(loader: str) -> str:
    mapping = {
        "Directory": "ЗагрузчикКаталога",
        "File": "ЗагрузчикФайла",
        "Subsystem": "ЗагрузчикИзПодсистемКонфигурации",
    }
    return mapping[loader]


def parse_bool(value: str) -> bool:
    return value.strip().lower() in {"1", "true", "yes", "y", "истина", "да"}


def build_enterprise_args(ib_connection: str, test_manager: bool = False) -> list[str]:
    args = ["ENTERPRISE"]
    if test_manager:
        args.append("/TestManager")

    if ib_connection.lstrip().startswith("/"):
        args.extend(shlex.split(ib_connection))
    else:
        args.extend(["/IBConnectionString", ib_connection])

    return args


def command_exists(value: str) -> bool:
    return Path(value).exists() or shutil.which(value) is not None


def bootstrap(args: argparse.Namespace) -> int:
    env_target = REPO_ROOT / args.env_file
    env_example = REPO_ROOT / ".env.example"
    local_config_root = REPO_ROOT / ".onec-test"

    actions = [
        "Ensure artifacts/ui, artifacts/xunit, artifacts/doctor, artifacts/packages, dist",
        "Ensure .onec-test",
        "Copy .env.example from skill template when missing",
        "Copy .env from .env.example when missing",
        "Copy VA and xUnit local config templates when missing",
    ]

    if args.dry_run:
        for action in actions:
            print(f"[dry-run] {action}")
        return 0

    ensure_directory(REPO_ROOT / "artifacts" / "ui")
    ensure_directory(REPO_ROOT / "artifacts" / "xunit")
    ensure_directory(REPO_ROOT / "artifacts" / "doctor")
    ensure_directory(REPO_ROOT / "artifacts" / "packages")
    ensure_directory(REPO_ROOT / "dist")
    ensure_directory(local_config_root)

    if not env_example.exists():
        shutil.copy2(SKILL_ROOT / "templates" / "config" / "env.template", env_example)
    if not env_target.exists():
        shutil.copy2(env_example, env_target)
    else:
        merge_env_template_file(env_target, env_example)

    ui_target = local_config_root / "VAParams.local.json"
    xunit_target = local_config_root / "XUnitParams.local.json"
    if not ui_target.exists():
        shutil.copy2(SKILL_ROOT / "templates" / "config" / "VAParams.template.json", ui_target)
    else:
        migrate_va_params_file(ui_target)
    if not xunit_target.exists():
        shutil.copy2(SKILL_ROOT / "templates" / "config" / "XUnitParams.template.json", xunit_target)

    print("Bootstrap completed.")
    print(f"Local env: {env_target}")
    print(f"Local config root: {local_config_root}")

    if args.skip_doctor:
        return 0

    doctor_args = argparse.Namespace(scope="All", env_file=args.env_file)
    return doctor(doctor_args)


def doctor(args: argparse.Namespace) -> int:
    env_map = load_env(REPO_ROOT / args.env_file)
    run_path = new_run_context("doctor", args.scope.lower())

    checks: list[dict[str, Any]] = []

    def add_check(name: str, passed: bool, severity: str, details: str) -> None:
        checks.append({"name": name, "passed": passed, "severity": severity, "details": details})

    def test_configured_path(setting_name: str, label: str, required: bool) -> None:
        severity = "required" if required else "optional"
        try:
            value = get_setting(env_map, setting_name, required=required)
            if value and command_exists(value):
                add_check(label, True, severity, value)
            elif value:
                add_check(label, False, severity, f"Configured path does not exist: {value}")
            elif not required:
                add_check(label, False, severity, "Not configured.")
        except RuntimeError as exc:
            add_check(label, False, severity, str(exc))

    add_check("git", shutil.which("git") is not None, "required", "Required for git-first workflow.")
    needs_runtime = args.scope in {"All", "UI", "XUnit"}
    test_configured_path("OVS_1C_BIN", "1C executable", needs_runtime)
    test_configured_path("OVS_VANESSA_EPF", "Vanessa Automation EPF", args.scope in {"All", "UI"})
    test_configured_path("OVS_XUNIT_EPF", "xUnitFor1C EPF", args.scope in {"All", "XUnit"})
    test_configured_path("OVS_VRUNNER", "vanessa-runner executable", False)
    test_configured_path("OVS_OSCRIPT", "oscript executable", False)

    try:
        ib_connection = get_setting(env_map, "OVS_IB_CONNECTION", required=needs_runtime)
        add_check("IB connection", bool(ib_connection), "required", ib_connection)
    except RuntimeError as exc:
        add_check("IB connection", False, "required", str(exc))

    summary = {
        "scope": args.scope,
        "createdAt": datetime.now().isoformat(timespec="seconds"),
        "runPath": str(run_path),
        "checks": checks,
        "failedRequired": sum(1 for check in checks if not check["passed"] and check["severity"] == "required"),
        "failedOptional": sum(1 for check in checks if not check["passed"] and check["severity"] == "optional"),
    }

    save_json(run_path / "summary.json", summary)
    lines = [
        f"{'PASS' if check['passed'] else 'FAIL'} [{check['severity']}] {check['name']} - {check['details']}"
        for check in checks
    ]
    save_text(run_path / "summary.txt", "\n".join(lines) + ("\n" if lines else ""))
    print(f"Doctor summary written to {run_path}")
    return 2 if summary["failedRequired"] else 0


def build_ui_va_config(
    feature_path: Path,
    libraries_path: Path,
    run_path: Path,
    tags: list[str] | None,
    env_map: dict[str, str],
) -> dict[str, Any]:
    screenshot_command = get_setting(env_map, "OVS_VA_SCREENSHOT_COMMAND")
    use_addin_for_screenshots = parse_bool(get_setting(env_map, "OVS_VA_USE_ADDIN_FOR_SCREENSHOTS", default="false"))
    screenshot_enabled = parse_bool(get_setting(env_map, "OVS_VA_ENABLE_SCREENSHOTS", default="false"))
    enable_screenshots = screenshot_enabled or bool(screenshot_command) or use_addin_for_screenshots

    config: dict[str, Any] = {
        "КаталогФич": str(feature_path),
        "КаталогиБиблиотек": [str(libraries_path)],
        "ДелатьСкриншотПриВозникновенииОшибки": enable_screenshots,
        "КаталогВыгрузкиСкриншотов": str(run_path / "screenshots"),
        "ДелатьЛогВыполненияСценариевВТекстовыйФайл": True,
        "ИмяФайлаЛогВыполненияСценариев": str(run_path / "va.log"),
        "ВыгружатьСтатусВыполненияСценариевВФайл": True,
        "ПутьКФайлуДляВыгрузкиСтатусаВыполненияСценариев": str(run_path / "status.txt"),
        "ДелатьОтчетВФорматеCucumberJson": True,
        "КаталогВыгрузкиCucumberJson": str(run_path / "cucumber"),
        "ДелатьОтчетВФорматеАллюр": True,
        "КаталогВыгрузки AllureБазовый": str(run_path / "allure"),
        "ПриравниватьPendingКFailed": True,
    }
    if screenshot_command:
        config["КомандаСделатьСкриншот"] = screenshot_command
    if use_addin_for_screenshots:
        config["ИспользоватьКомпонентуVanessaExt"] = True
        config["ИспользоватьВнешнююКомпонентуДляСкриншотов"] = True
    if tags:
        config["СписокТеговОтбор"] = tags
    return config


def split_tags(raw_tags: str | None) -> list[str]:
    if not raw_tags:
        return []
    return [tag.strip() for tag in raw_tags.split(",") if tag.strip()]


def run_ui(args: argparse.Namespace) -> int:
    env_map = load_env(REPO_ROOT / args.env_file)
    run_path = new_run_context("ui", "run")
    feature_setting = "OVS_UI_SMOKE_PATH" if args.profile == "Smoke" else "OVS_UI_PATH"
    feature_path = repo_path(args.feature_path or get_setting(env_map, feature_setting, default="examples/ui"))
    libraries_path = repo_path(get_setting(env_map, "OVS_UI_LIBRARIES", default="examples/ui/libraries"))
    config_path = run_path / "VAParams.generated.json"
    status_path = run_path / "status.txt"
    log_path = run_path / "stdout.log"
    command_path = run_path / "command.txt"

    tags = split_tags(args.tags)
    save_json(config_path, build_ui_va_config(feature_path, libraries_path, run_path, tags, env_map))

    if args.backend == "Native":
        env_required = load_env(REPO_ROOT / args.env_file)
        bin_path = get_setting(env_required, "OVS_1C_BIN", required=True)
        ib = get_setting(env_required, "OVS_IB_CONNECTION", required=True)
        user = get_setting(env_required, "OVS_DB_USER")
        password = get_setting(env_required, "OVS_DB_PASSWORD")
        vanessa = get_setting(env_required, "OVS_VANESSA_EPF", required=True)

        command_args = build_enterprise_args(ib, test_manager=True)
        if user:
            command_args.append(f"/N{user}")
        if password:
            command_args.append(f"/P{password}")
        command_args.extend(["/Execute", vanessa, "/C", f"StartFeaturePlayer;VAParams={config_path}"])
        write_command_file(command_path, bin_path, command_args)
        result = invoke_logged_command(bin_path, command_args, log_path, args.dry_run)
    else:
        vrunner = get_setting(env_map, "OVS_VRUNNER", required=True)
        command_args = ["vanessa", "--path", str(feature_path), "--workspace", str(REPO_ROOT), "--vanessasettings", str(config_path)]
        if tags:
            command_args.extend(["--tags-filter", ",".join(tags)])
        write_command_file(command_path, vrunner, command_args)
        result = invoke_logged_command(vrunner, command_args, log_path, args.dry_run)

    status_code = result["exit_code"]
    if status_path.exists():
        try:
            status_code = int(status_path.read_text(encoding="utf-8").strip())
        except ValueError:
            pass

    save_json(
        run_path / "summary.json",
        {
            "mode": "ui-run",
            "backend": args.backend,
            "profile": args.profile,
            "featurePath": str(feature_path),
            "tags": tags,
            "runPath": str(run_path),
            "commandFile": str(command_path),
            "generatedConfig": str(config_path),
            "statusCode": status_code,
            "launched": result["launched"],
        },
    )
    print(f"UI run artifacts: {run_path}")
    return status_code


def debug_ui(args: argparse.Namespace) -> int:
    env_map = load_env(REPO_ROOT / args.env_file)
    run_path = new_run_context("ui", "debug")
    feature_path = repo_path(args.feature_path or get_setting(env_map, "OVS_UI_SMOKE_PATH", default="examples/ui"))
    libraries_path = repo_path(get_setting(env_map, "OVS_UI_LIBRARIES", default="examples/ui/libraries"))
    config_path = run_path / "VAParams.debug.json"
    log_path = run_path / "stdout.log"
    command_path = run_path / "command.txt"

    config = {
        "КаталогФич": str(feature_path),
        "КаталогиБиблиотек": [str(libraries_path)],
        "ДелатьЛогВыполненияСценариевВТекстовыйФайл": True,
        "ИмяФайлаЛогВыполненияСценариев": str(run_path / "va-debug.log"),
    }
    save_json(config_path, config)

    bin_path = get_setting(env_map, "OVS_1C_BIN", required=True)
    ib = get_setting(env_map, "OVS_IB_CONNECTION", required=True)
    user = get_setting(env_map, "OVS_DB_USER")
    password = get_setting(env_map, "OVS_DB_PASSWORD")
    vanessa = get_setting(env_map, "OVS_VANESSA_EPF", required=True)

    command_args = build_enterprise_args(ib, test_manager=True)
    if user:
        command_args.append(f"/N{user}")
    if password:
        command_args.append(f"/P{password}")
    command_args.extend(["/Execute", vanessa, "/C", f"VAParams={config_path}"])
    write_command_file(command_path, bin_path, command_args)
    result = invoke_logged_command(bin_path, command_args, log_path, args.dry_run)

    save_json(
        run_path / "summary.json",
        {
            "mode": "ui-debug",
            "featurePath": str(feature_path),
            "runPath": str(run_path),
            "launched": result["launched"],
            "note": "Debug mode loads VAParams and opens Vanessa Automation without StartFeaturePlayer.",
        },
    )
    print(f"UI debug artifacts: {run_path}")
    return result["exit_code"]


def build_xunit_summary(mode: str, args: argparse.Namespace, tests_path: Path, run_path: Path, command_path: Path, report_path: Path | None, status_code: int) -> dict[str, Any]:
    payload = {
        "mode": mode,
        "backend": args.backend,
        "loader": args.loader,
        "testsPath": str(tests_path),
        "runPath": str(run_path),
        "commandFile": str(command_path),
        "statusCode": status_code,
    }
    if hasattr(args, "profile"):
        payload["profile"] = args.profile
    if report_path is not None:
        payload["reportPath"] = str(report_path)
    return payload


def run_xunit(args: argparse.Namespace) -> int:
    env_map = load_env(REPO_ROOT / args.env_file)
    run_path = new_run_context("xunit", "run")
    tests_setting = "OVS_XUNIT_SMOKE_PATH" if args.profile == "Smoke" else "OVS_XUNIT_PATH"
    tests_path = repo_path(args.tests_path or get_setting(env_map, tests_setting, default="examples/xunit"))
    command_path = run_path / "command.txt"
    log_path = run_path / "stdout.log"
    status_path = run_path / "status.txt"
    report_path = run_path / "junit.xml"

    if args.backend == "Native":
        bin_path = get_setting(env_map, "OVS_1C_BIN", required=True)
        ib = get_setting(env_map, "OVS_IB_CONNECTION", required=True)
        user = get_setting(env_map, "OVS_DB_USER")
        password = get_setting(env_map, "OVS_DB_PASSWORD")
        xunit = get_setting(env_map, "OVS_XUNIT_EPF", required=True)
        loader_name = resolve_loader(args.loader)
        xdd = f'xddRun {loader_name} "{tests_path}";xddReport ГенераторОтчетаJUnitXML "{report_path}";xddShutdown;'

        command_args = build_enterprise_args(ib)
        if user:
            command_args.append(f"/N{user}")
        if password:
            command_args.append(f"/P{password}")
        command_args.extend(["/Execute", xunit, "/C", xdd])
        write_command_file(command_path, bin_path, command_args)
        result = invoke_logged_command(bin_path, command_args, log_path, args.dry_run)
        save_text(status_path, f"{result['exit_code']}\n")
        status_code = result["exit_code"]
    else:
        vrunner = get_setting(env_map, "OVS_VRUNNER", required=True)
        ib = get_setting(env_map, "OVS_IB_CONNECTION", required=True)
        user = get_setting(env_map, "OVS_DB_USER")
        password = get_setting(env_map, "OVS_DB_PASSWORD")
        xunit = get_setting(env_map, "OVS_XUNIT_EPF", required=True)
        xunit_config = REPO_ROOT / ".onec-test" / "XUnitParams.local.json"
        command_args = [
            "xunit",
            str(tests_path),
            "--ibconnection",
            ib,
            "--pathxunit",
            xunit,
            "--xddConfig",
            str(xunit_config),
            "--reportsxunit",
            f"ГенераторОтчетаJUnitXML{{{report_path}}}",
            "--xddExitCodePath",
            str(status_path),
        ]
        if user:
            command_args.extend(["--db-user", user])
        if password:
            command_args.extend(["--db-pwd", password])

        write_command_file(command_path, vrunner, command_args)
        result = invoke_logged_command(vrunner, command_args, log_path, args.dry_run)
        status_code = result["exit_code"]
        if status_path.exists():
            try:
                status_code = int(status_path.read_text(encoding="utf-8").strip())
            except ValueError:
                pass

    save_json(run_path / "summary.json", build_xunit_summary("xunit-run", args, tests_path, run_path, command_path, report_path, status_code))
    print(f"xUnit run artifacts: {run_path}")
    return status_code


def debug_xunit(args: argparse.Namespace) -> int:
    env_map = load_env(REPO_ROOT / args.env_file)
    run_path = new_run_context("xunit", "debug")
    tests_path = repo_path(args.tests_path or get_setting(env_map, "OVS_XUNIT_SMOKE_PATH", default="examples/xunit"))
    command_path = run_path / "command.txt"
    log_path = run_path / "stdout.log"
    status_path = run_path / "status.txt"
    report_path = run_path / "junit.xml"

    if args.backend == "Native":
        bin_path = get_setting(env_map, "OVS_1C_BIN", required=True)
        ib = get_setting(env_map, "OVS_IB_CONNECTION", required=True)
        user = get_setting(env_map, "OVS_DB_USER")
        password = get_setting(env_map, "OVS_DB_PASSWORD")
        xunit = get_setting(env_map, "OVS_XUNIT_EPF", required=True)
        loader_name = resolve_loader(args.loader)
        xdd = f'xddRun {loader_name} "{tests_path}";xddReport ГенераторОтчетаJUnitXML "{report_path}";'

        command_args = build_enterprise_args(ib)
        if user:
            command_args.append(f"/N{user}")
        if password:
            command_args.append(f"/P{password}")
        command_args.extend(["/Execute", xunit, "/C", xdd])
        write_command_file(command_path, bin_path, command_args)
        result = invoke_logged_command(bin_path, command_args, log_path, args.dry_run)
        save_text(status_path, f"{result['exit_code']}\n")
        status_code = result["exit_code"]
    else:
        vrunner = get_setting(env_map, "OVS_VRUNNER", required=True)
        ib = get_setting(env_map, "OVS_IB_CONNECTION", required=True)
        user = get_setting(env_map, "OVS_DB_USER")
        password = get_setting(env_map, "OVS_DB_PASSWORD")
        xunit = get_setting(env_map, "OVS_XUNIT_EPF", required=True)
        xunit_config = REPO_ROOT / ".onec-test" / "XUnitParams.local.json"
        command_args = [
            "xunit",
            str(tests_path),
            "--ibconnection",
            ib,
            "--pathxunit",
            xunit,
            "--xddConfig",
            str(xunit_config),
            "--reportsxunit",
            f"ГенераторОтчетаJUnitXML{{{report_path}}}",
            "--xddExitCodePath",
            str(status_path),
            "--xdddebug",
            "--no-shutdown",
        ]
        if user:
            command_args.extend(["--db-user", user])
        if password:
            command_args.extend(["--db-pwd", password])

        write_command_file(command_path, vrunner, command_args)
        result = invoke_logged_command(vrunner, command_args, log_path, args.dry_run)
        status_code = result["exit_code"]
        if status_path.exists():
            try:
                status_code = int(status_path.read_text(encoding="utf-8").strip())
            except ValueError:
                pass

    summary = build_xunit_summary("xunit-debug", args, tests_path, run_path, command_path, report_path, status_code)
    summary["note"] = "Debug mode keeps more context and avoids shutdown when the backend supports it."
    save_json(run_path / "summary.json", summary)
    print(f"xUnit debug artifacts: {run_path}")
    return status_code


def collect_artifacts(args: argparse.Namespace) -> int:
    source_path = repo_path(args.run_path)
    if not source_path.exists():
        raise RuntimeError(f"Run path not found: {source_path}")

    packages_root = ensure_directory(REPO_ROOT / "artifacts" / "packages")
    destination = packages_root / args.output_name
    if destination.exists():
        destination.unlink()

    with zipfile.ZipFile(destination, "w", compression=zipfile.ZIP_DEFLATED) as archive:
        for path in sorted(source_path.rglob("*")):
            if path.is_file():
                archive.write(path, path.relative_to(source_path))

    print(f"Created bundle: {destination}")
    return 0


def should_package_path(path: Path) -> bool:
    ignored_names = {".DS_Store", "Thumbs.db"}
    ignored_dirs = {"__pycache__", ".pytest_cache", ".mypy_cache"}
    ignored_suffixes = {".pyc", ".pyo", ".swp", ".swo"}

    parts = set(path.parts)
    if parts & ignored_dirs:
        return False
    if path.name in ignored_names:
        return False
    if path.suffix in ignored_suffixes:
        return False
    return True


def copy_package_tree(source: Path, target: Path) -> None:
    if source.is_dir():
        for path in sorted(source.rglob("*")):
            relative = path.relative_to(source)
            if not should_package_path(relative):
                continue
            destination = target / relative
            if path.is_dir():
                destination.mkdir(parents=True, exist_ok=True)
            elif path.is_file():
                destination.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(path, destination)
    elif should_package_path(source):
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, target)


def package_skill(args: argparse.Namespace) -> int:
    dist_root = ensure_directory(REPO_ROOT / "dist")
    output_name = args.output_name or f"onec-vanessa-skill-{datetime.now().strftime('%Y%m%d-%H%M%S')}.zip"
    destination = dist_root / output_name
    include_paths = [
        "README.md",
        "install",
        "skill",
        "examples",
        "ci",
        "docs",
        ".env.example",
    ]

    if args.dry_run:
        for include_path in include_paths:
            print(f"[dry-run] include {include_path}")
        print(f"[dry-run] output {destination}")
        return 0

    staging_root = Path(tempfile.mkdtemp(prefix="onec-vanessa-skill-"))
    try:
        for relative in include_paths:
            source = REPO_ROOT / relative
            if not source.exists():
                continue
            target = staging_root / relative
            copy_package_tree(source, target)

        if destination.exists():
            destination.unlink()

        with zipfile.ZipFile(destination, "w", compression=zipfile.ZIP_DEFLATED) as archive:
            for path in sorted(staging_root.rglob("*")):
                if path.is_file():
                    archive.write(path, path.relative_to(staging_root))
    finally:
        shutil.rmtree(staging_root, ignore_errors=True)

    print(f"Package created: {destination}")
    return 0


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Cross-platform 1C testing orchestration CLI for Vanessa Automation and xUnitFor1C."
    )
    subparsers = parser.add_subparsers(dest="command", required=True)

    bootstrap_parser = subparsers.add_parser("bootstrap", help="Prepare local workspace and optional doctor run.")
    bootstrap_parser.add_argument("--env-file", default=".env")
    bootstrap_parser.add_argument("--skip-doctor", action="store_true")
    bootstrap_parser.add_argument("--dry-run", action="store_true")
    bootstrap_parser.set_defaults(func=bootstrap)

    doctor_parser = subparsers.add_parser("doctor", help="Check required and optional local dependencies.")
    doctor_parser.add_argument("--scope", choices=["All", "UI", "XUnit", "Package"], default="All")
    doctor_parser.add_argument("--env-file", default=".env")
    doctor_parser.set_defaults(func=doctor)

    run_ui_parser = subparsers.add_parser("run-ui", help="Run Vanessa Automation UI/BDD tests.")
    run_ui_parser.add_argument("--feature-path")
    run_ui_parser.add_argument("--tags")
    run_ui_parser.add_argument("--backend", choices=["Native", "VRunner"], default="Native")
    run_ui_parser.add_argument("--profile", choices=["CI", "Local", "Smoke"], default="CI")
    run_ui_parser.add_argument("--env-file", default=".env")
    run_ui_parser.add_argument("--dry-run", action="store_true")
    run_ui_parser.set_defaults(func=run_ui)

    debug_ui_parser = subparsers.add_parser("debug-ui", help="Open Vanessa Automation without StartFeaturePlayer.")
    debug_ui_parser.add_argument("--feature-path")
    debug_ui_parser.add_argument("--env-file", default=".env")
    debug_ui_parser.add_argument("--dry-run", action="store_true")
    debug_ui_parser.set_defaults(func=debug_ui)

    run_xunit_parser = subparsers.add_parser("run-xunit", help="Run xUnitFor1C tests.")
    run_xunit_parser.add_argument("--tests-path")
    run_xunit_parser.add_argument("--loader", choices=["Directory", "File", "Subsystem"], default="Directory")
    run_xunit_parser.add_argument("--backend", choices=["Native", "VRunner"], default="Native")
    run_xunit_parser.add_argument("--profile", choices=["Custom", "Smoke", "Fast", "Full"], default="Custom")
    run_xunit_parser.add_argument("--env-file", default=".env")
    run_xunit_parser.add_argument("--dry-run", action="store_true")
    run_xunit_parser.set_defaults(func=run_xunit)

    debug_xunit_parser = subparsers.add_parser("debug-xunit", help="Run xUnitFor1C in debug-oriented mode.")
    debug_xunit_parser.add_argument("--tests-path")
    debug_xunit_parser.add_argument("--loader", choices=["Directory", "File", "Subsystem"], default="Directory")
    debug_xunit_parser.add_argument("--backend", choices=["Native", "VRunner"], default="Native")
    debug_xunit_parser.add_argument("--env-file", default=".env")
    debug_xunit_parser.add_argument("--dry-run", action="store_true")
    debug_xunit_parser.set_defaults(func=debug_xunit)

    collect_parser = subparsers.add_parser("collect-artifacts", help="Zip one run directory into artifacts/packages.")
    collect_parser.add_argument("--run-path", required=True)
    collect_parser.add_argument("--output-name", default="artifacts-bundle.zip")
    collect_parser.set_defaults(func=collect_artifacts)

    package_parser = subparsers.add_parser("package-skill", help="Create a reusable zip archive in dist/.")
    package_parser.add_argument("--output-name")
    package_parser.add_argument("--dry-run", action="store_true")
    package_parser.set_defaults(func=package_skill)

    return parser


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)
    try:
        return args.func(args)
    except RuntimeError as exc:
        print(str(exc), file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
