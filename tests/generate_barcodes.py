#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# dependencies = [
#     "pillow>=12.2.0",
#     "zxing-cpp>=3.0.0",
# ]
# ///
"""Generate sample barcode images for VOCR barcode detection checks.

Run with:
    uv run --script tests/generate_barcodes.py
"""

from __future__ import annotations

import argparse
import json
import re
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable

from PIL import Image, ImageDraw, ImageFont
import zxingcpp


@dataclass(frozen=True)
class Symbology:
    key: str
    label: str
    zxing_format: str
    payload: str
    suite: str
    notes: str = ""


VISION_SYMBOLOGIES: tuple[Symbology, ...] = (
    Symbology("aztec", "Aztec", "Aztec", "VOCR-AZTEC-1234", "vision"),
    Symbology("codabar", "Codabar", "Codabar", "A123456A", "vision"),
    Symbology("code128", "Code 128", "Code128", "VOCR Code 128 1234", "vision"),
    Symbology("code39", "Code 39", "Code39", "VOCR-123", "vision"),
    Symbology(
        "code39_full_ascii",
        "Code 39 Full ASCII",
        "Code39Ext",
        "VOCR-full-ASCII-123",
        "vision",
    ),
    Symbology("code93", "Code 93", "Code93", "VOCR-123", "vision"),
    Symbology("datamatrix", "Data Matrix", "DataMatrix", "VOCR Data Matrix 1234", "vision"),
    Symbology("ean13", "EAN-13", "EAN13", "5901234123457", "vision"),
    Symbology("ean8", "EAN-8", "EAN8", "96385074", "vision"),
    Symbology("gs1_databar", "GS1 DataBar", "DataBarStkOmni", "0101234567890128", "vision"),
    Symbology(
        "gs1_databar_expanded",
        "GS1 DataBar Expanded",
        "DataBarExpanded",
        "(01)01234567890128(17)250101",
        "vision",
    ),
    Symbology(
        "gs1_databar_limited",
        "GS1 DataBar Limited",
        "DataBarLimited",
        "0101234567890128",
        "vision",
    ),
    Symbology("i2of5", "Interleaved 2 of 5", "ITF", "12345670", "vision"),
    Symbology("itf14", "ITF-14", "ITF14", "10012345678902", "vision"),
    Symbology("micro_pdf417", "MicroPDF417", "MicroPDF417", "VOCR MicroPDF417 1234", "vision"),
    Symbology("micro_qr", "Micro QR code", "MicroQRCode", "VOCR123", "vision"),
    Symbology("pdf417", "PDF417", "PDF417", "VOCR PDF417 1234", "vision"),
    Symbology("qr", "QR code", "QRCode", "VOCR QR 1234", "vision"),
    Symbology("upce", "UPC-E", "UPCE", "01234565", "vision"),
)

EXTRA_SYMBOLOGIES: tuple[Symbology, ...] = (
    Symbology("aztec_rune", "Aztec Rune", "AztecRune", "42", "extra"),
    Symbology("compact_pdf417", "Compact PDF417", "CompactPDF417", "VOCR Compact PDF417", "extra"),
    Symbology("code32", "Code 32", "Code32", "01234567", "extra"),
    Symbology("databar_omni", "GS1 DataBar Omnidirectional", "DataBarOmni", "0101234567890128", "extra"),
    Symbology("databar_stacked", "GS1 DataBar Stacked", "DataBarStk", "0101234567890128", "extra"),
    Symbology(
        "databar_stacked_omni",
        "GS1 DataBar Stacked Omnidirectional",
        "DataBarStkOmni",
        "0101234567890128",
        "extra",
    ),
    Symbology(
        "databar_expanded_stacked",
        "GS1 DataBar Expanded Stacked",
        "DataBarExpStk",
        "(01)01234567890128(17)250101",
        "extra",
    ),
    Symbology("ean2", "EAN-2 add-on", "EAN2", "12", "extra"),
    Symbology("ean5", "EAN-5 add-on", "EAN5", "12345", "extra"),
    Symbology("maxicode", "MaxiCode", "MaxiCode", "VOCR MaxiCode 1234", "extra"),
    Symbology("pzn", "PZN", "PZN", "12345678", "extra"),
    Symbology("r_mqr", "Rectangular Micro QR", "RMQRCode", "VOCR Rectangular Micro QR", "extra"),
    Symbology("upca", "UPC-A", "UPCA", "042100005264", "extra"),
)

QR_PAYLOADS: tuple[Symbology, ...] = (
    Symbology("qr_text", "QR plain text", "QRCode", "VOCR plain text QR sample", "qr"),
    Symbology("qr_url", "QR URL", "QRCode", "https://github.com/chigkim/VOCR", "qr"),
    Symbology("qr_mailto", "QR mailto email", "QRCode", "mailto:support@example.com?subject=VOCR%20QR%20Test", "qr"),
    Symbology(
        "qr_email_matmsg",
        "QR MATMSG email",
        "QRCode",
        "MATMSG:TO:support@example.com;SUB:VOCR QR Test;BODY:Hello from VOCR;;",
        "qr",
    ),
    Symbology("qr_phone", "QR phone", "QRCode", "tel:+15551234567", "qr"),
    Symbology("qr_sms", "QR SMS", "QRCode", "SMSTO:+15551234567:VOCR QR SMS test", "qr"),
    Symbology("qr_wifi_wpa", "QR Wi-Fi WPA", "QRCode", "WIFI:T:WPA;S:VOCR-Test;P:CorrectHorse123;H:false;;", "qr"),
    Symbology("qr_wifi_hidden", "QR Wi-Fi hidden", "QRCode", "WIFI:T:WPA;S:Hidden-VOCR;P:HiddenPass123;H:true;;", "qr"),
    Symbology("qr_wifi_wep", "QR Wi-Fi WEP", "QRCode", "WIFI:T:WEP;S:Legacy-VOCR;P:abcde;H:false;;", "qr"),
    Symbology("qr_wifi_open", "QR Wi-Fi open", "QRCode", "WIFI:T:nopass;S:VOCR-Guest;H:false;;", "qr"),
    Symbology(
        "qr_vcard",
        "QR vCard contact",
        "QRCode",
        "BEGIN:VCARD\nVERSION:3.0\nN:Doe;Jane;;;\nFN:Jane Doe\nORG:VOCR Test\nTEL:+15551234567\n"
        "EMAIL:jane@example.com\nURL:https://example.com\nEND:VCARD",
        "qr",
    ),
    Symbology(
        "qr_mecard",
        "QR MeCard contact",
        "QRCode",
        "MECARD:N:Doe,Jane;ORG:VOCR Test;TEL:+15551234567;EMAIL:jane@example.com;"
        "URL:https://example.com;;",
        "qr",
    ),
    Symbology("qr_geo", "QR geo location", "QRCode", "geo:37.7749,-122.4194?q=37.7749,-122.4194(VOCR)", "qr"),
    Symbology(
        "qr_calendar",
        "QR calendar event",
        "QRCode",
        "BEGIN:VCALENDAR\nVERSION:2.0\nBEGIN:VEVENT\nSUMMARY:VOCR QR Test\nDTSTART:20260511T140000Z\n"
        "DTEND:20260511T143000Z\nLOCATION:Online\nDESCRIPTION:QR calendar payload test\nEND:VEVENT\nEND:VCALENDAR",
        "qr",
    ),
    Symbology(
        "qr_bookmark",
        "QR bookmark",
        "QRCode",
        "MEBKM:TITLE:VOCR Project;URL:https://github.com/chigkim/VOCR;;",
        "qr",
    ),
    Symbology(
        "qr_otp",
        "QR one-time password",
        "QRCode",
        "otpauth://totp/VOCR:demo@example.com?secret=JBSWY3DPEHPK3PXP&issuer=VOCR",
        "qr",
    ),
    Symbology(
        "qr_bitcoin",
        "QR bitcoin URI",
        "QRCode",
        "bitcoin:bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kygt080?amount=0.001&label=VOCR",
        "qr",
    ),
    Symbology("qr_app_url", "QR app URL", "QRCode", "vocr://scan?source=qr-test", "qr"),
)

VISION_DETECT_ONLY = {
    "code39_checksum": "Code 39 checksum is a detector variant; this encoder exposes Code39.",
    "code39_full_ascii_checksum": "Code 39 Full ASCII checksum is a detector variant; this encoder exposes Code39Ext.",
    "code93i": "ZXing-C++ does not expose a separate Code 93i writer.",
    "msi_plessey": "ZXing-C++ does not expose an MSI Plessey writer.",
}

SCRIPT_DIR = Path(__file__).resolve().parent
DEFAULT_SHEETS = (
    {
        "path": SCRIPT_DIR / "barcode_symbologies.png",
        "symbologies": VISION_SYMBOLOGIES,
        "scale": 4,
        "columns": 2,
    },
    {
        "path": SCRIPT_DIR / "qr_payloads.png",
        "symbologies": QR_PAYLOADS,
        "scale": 6,
        "columns": 3,
    },
)


def all_symbologies() -> tuple[Symbology, ...]:
    return VISION_SYMBOLOGIES + EXTRA_SYMBOLOGIES


def suite_symbologies(suite: str) -> tuple[Symbology, ...]:
    if suite == "vision":
        return VISION_SYMBOLOGIES
    if suite == "all":
        return all_symbologies()
    if suite == "qr":
        return QR_PAYLOADS
    raise ValueError(f"Unknown suite: {suite}")


def slugify(value: str) -> str:
    return re.sub(r"[^a-z0-9]+", "_", value.lower()).strip("_")


def selected_symbologies(args: argparse.Namespace) -> list[Symbology]:
    candidates = suite_symbologies(args.suite)
    by_key = {sym.key: sym for sym in candidates}

    if not args.symbology:
        return list(candidates)

    selected: list[Symbology] = []
    for requested in args.symbology:
        key = slugify(requested)
        symbology = by_key.get(key)
        if symbology is None:
            known = ", ".join(sorted(by_key))
            raise SystemExit(f"Unknown symbology '{requested}'. Known values: {known}")
        selected.append(symbology)
    return selected


def compact_text(value: object, limit: int = 96) -> str:
    text = str(value).replace("\n", "\\n")
    if len(text) <= limit:
        return text
    return text[:limit - 3] + "..."


def make_barcode(
    symbology: Symbology,
    scale: int,
    output_format: str,
) -> tuple[dict[str, object], Image.Image | str]:
    fmt = getattr(zxingcpp.BarcodeFormat, symbology.zxing_format)
    barcode = zxingcpp.create_barcode(symbology.payload, fmt)
    if not barcode.valid:
        raise ValueError(barcode.error or f"{symbology.key} did not produce a valid barcode")

    if output_format == "svg":
        image = zxingcpp.write_barcode_to_svg(barcode, scale=scale, add_hrt=True, add_quiet_zones=True)
    else:
        image_buffer = zxingcpp.write_barcode_to_image(
            barcode, scale=scale, add_hrt=True, add_quiet_zones=True)
        image = Image.fromarray(image_buffer)

    manifest_entry = {
        "key": symbology.key,
        "label": symbology.label,
        "suite": symbology.suite,
        "zxing_format": symbology.zxing_format,
        "payload": symbology.payload,
        "encoded_text": barcode.text,
        "symbology_identifier": barcode.symbology_identifier,
        "format": output_format,
    }
    if symbology.notes:
        manifest_entry["notes"] = symbology.notes

    return manifest_entry, image


def write_barcode(symbology: Symbology, args: argparse.Namespace) -> dict[str, object]:
    manifest_entry, image = make_barcode(symbology, args.scale, args.format)
    filename = f"{symbology.key}.{args.format}"
    output_path = args.output_dir / filename

    if args.format == "svg":
        output_path.write_text(str(image), encoding="utf-8")
    else:
        assert isinstance(image, Image.Image)
        image.save(output_path)

    manifest_entry["file"] = str(output_path)
    return manifest_entry


def load_font(size: int) -> ImageFont.ImageFont:
    for font_path in (
        "/System/Library/Fonts/Supplemental/Arial.ttf",
        "/Library/Fonts/Arial.ttf",
    ):
        try:
            return ImageFont.truetype(font_path, size)
        except OSError:
            pass
    return ImageFont.load_default()


def text_size(draw: ImageDraw.ImageDraw, text: str, font: ImageFont.ImageFont) -> tuple[int, int]:
    left, top, right, bottom = draw.textbbox((0, 0), text, font=font)
    return right - left, bottom - top


def write_contact_sheet(
    symbologies: list[Symbology],
    output_path: Path,
    scale: int,
    columns: int,
    style: str,
) -> None:
    title_font = load_font(18)
    detail_font = load_font(13)
    padding = 18
    label_gap = 8
    image_gap = 16
    min_cell_width = 360
    placeholder = Image.new("RGB", (1, 1), "white")
    draw = ImageDraw.Draw(placeholder)

    items: list[tuple[Symbology, dict[str, object], Image.Image]] = []
    for symbology in symbologies:
        entry, image = make_barcode(symbology, scale, "png")
        assert isinstance(image, Image.Image)
        items.append((symbology, entry, image.convert("RGB")))

    if style == "scan":
        padding = 80
        scan_items: list[tuple[Symbology, dict[str, object], Image.Image]] = []
        for symbology, entry, image in items:
            if max(image.size) < 140 or min(image.size) < 100:
                image = image.resize(
                    (image.width * 2, image.height * 2),
                    Image.Resampling.NEAREST,
                )
            scan_items.append((symbology, entry, image))

        cell_width = max(image.width for _, _, image in scan_items) + padding * 2
        cell_height = max(image.height for _, _, image in scan_items) + padding * 2
        rows = [scan_items[index:index + columns] for index in range(0, len(scan_items), columns)]
        sheet = Image.new("RGB", (cell_width * columns, cell_height * len(rows)), "white")

        for row_index, row in enumerate(rows):
            for column_index, (_, _, image) in enumerate(row):
                x = column_index * cell_width + (cell_width - image.width) // 2
                y = row_index * cell_height + (cell_height - image.height) // 2
                sheet.paste(image, (x, y))

        output_path.parent.mkdir(parents=True, exist_ok=True)
        sheet.save(output_path)
        return

    cell_width = max(min_cell_width, max(image.width for _, _, image in items) + padding * 2)
    title_height = text_size(draw, "Barcode", title_font)[1]
    detail_height = text_size(draw, "payload", detail_font)[1]
    label_height = title_height + detail_height + label_gap + image_gap

    rows = [items[index:index + columns] for index in range(0, len(items), columns)]
    row_heights = [
        max(image.height + label_height + padding * 2 for _, _, image in row)
        for row in rows
    ]
    sheet_width = cell_width * columns + padding
    sheet_height = sum(row_heights) + padding * (len(rows) + 1)
    sheet = Image.new("RGB", (sheet_width, sheet_height), "white")
    draw = ImageDraw.Draw(sheet)

    y = padding
    for row, row_height in zip(rows, row_heights, strict=True):
        x = padding
        for symbology, entry, image in row:
            cell_box = (x, y, x + cell_width - padding, y + row_height)
            draw.rounded_rectangle(cell_box, radius=8, outline=(190, 190, 190), width=1)

            title = f"{symbology.label} ({symbology.key})"
            detail = f"Payload: {compact_text(entry['encoded_text'])}"
            draw.text((x + padding, y + padding), title, fill=(0, 0, 0), font=title_font)
            draw.text(
                (x + padding, y + padding + title_height + label_gap),
                detail,
                fill=(55, 55, 55),
                font=detail_font,
            )

            image_x = x + (cell_width - padding - image.width) // 2
            image_y = y + padding + label_height
            sheet.paste(image, (image_x, image_y))
            x += cell_width
        y += row_height + padding

    output_path.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(output_path)


def print_list(symbologies: Iterable[Symbology]) -> None:
    symbologies = list(symbologies)
    width = max(len(sym.key) for sym in symbologies)
    for sym in symbologies:
        print(f"{sym.key:<{width}}  {sym.label} ({sym.zxing_format})")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Generate barcode samples using uv-managed Python dependencies.")
    parser.add_argument(
        "--output-dir",
        type=Path,
        default=Path("barcode_samples"),
        help="Directory to write generated barcodes and manifest.json.",
    )
    parser.add_argument(
        "--suite",
        choices=("vision", "all", "qr"),
        default="vision",
        help="Generate VOCR/Vision barcode symbologies, extra ZXing-C++ writers, or common QR payload types.",
    )
    parser.add_argument(
        "--symbology",
        action="append",
        help="Generate only this symbology key. May be passed more than once.",
    )
    parser.add_argument("--format", choices=("png", "svg"), default="png")
    parser.add_argument("--scale", type=int, default=4, help="Barcode render scale.")
    parser.add_argument(
        "--contact-sheet",
        type=Path,
        help="Also write all generated symbologies into one PNG contact sheet.",
    )
    parser.add_argument(
        "--sheet-style",
        choices=("labeled", "scan"),
        default="labeled",
        help="Use labels for review, or a cleaner barcode-only sheet for detection testing.",
    )
    parser.add_argument("--sheet-columns", type=int, default=2, help="Columns in --contact-sheet output.")
    parser.add_argument("--list", action="store_true", help="List available symbology keys and exit.")
    parser.add_argument("--quiet", action="store_true", help="Only print errors.")
    return parser.parse_args()


def generate_default_sheets() -> int:
    for sheet in DEFAULT_SHEETS:
        write_contact_sheet(
            list(sheet["symbologies"]),
            sheet["path"],
            sheet["scale"],
            sheet["columns"],
            "scan",
        )
        print(f"generated {sheet['path']}")
    return 0


def main() -> int:
    if len(sys.argv) == 1:
        return generate_default_sheets()

    args = parse_args()
    if args.sheet_columns < 1:
        raise SystemExit("--sheet-columns must be at least 1")
    symbologies = selected_symbologies(args)

    if args.list:
        print_list(symbologies)
        if args.suite == "vision":
            print("\nVision detector variants without separate writers:")
            for key, reason in sorted(VISION_DETECT_ONLY.items()):
                print(f"{key}: {reason}")
        return 0

    args.output_dir.mkdir(parents=True, exist_ok=True)

    generated: list[dict[str, object]] = []
    failures: list[dict[str, str]] = []
    for symbology in symbologies:
        try:
            entry = write_barcode(symbology, args)
            generated.append(entry)
            if not args.quiet:
                print(f"generated {entry['file']}")
        except Exception as error:
            failures.append({"key": symbology.key, "error": str(error)})
            print(f"failed {symbology.key}: {error}")

    if args.contact_sheet and generated:
        generated_keys = {str(entry["key"]) for entry in generated}
        generated_symbologies = [sym for sym in symbologies if sym.key in generated_keys]
        write_contact_sheet(
            generated_symbologies,
            args.contact_sheet,
            args.scale,
            args.sheet_columns,
            args.sheet_style,
        )
        if not args.quiet:
            print(f"generated {args.contact_sheet}")

    manifest = {
        "generated": generated,
        "failures": failures,
        "detect_only": VISION_DETECT_ONLY if args.suite == "vision" else {},
    }
    if args.contact_sheet:
        manifest["contact_sheet"] = str(args.contact_sheet)
    manifest_path = args.output_dir / "manifest.json"
    manifest_path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")

    if failures:
        print(f"Wrote {len(generated)} barcode(s); {len(failures)} failed. See {manifest_path}.")
        return 1

    if not args.quiet:
        print(f"Wrote {len(generated)} barcode(s) and {manifest_path}.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
