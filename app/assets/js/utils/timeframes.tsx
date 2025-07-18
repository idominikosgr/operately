import { match } from "ts-pattern";

import * as api from "@/api";
import * as Time from "@/utils/time";

//
// Type definitions
//

export type TimeframeType = "month" | "quarter" | "year" | "days";

export interface Timeframe {
  startDate: Date | null;
  endDate: Date | null;
  type: TimeframeType;
}

//
// Parsing and serializing the timeframe for GraphQL
//

export function parse(timeframe: api.Timeframe): Timeframe {
  return {
    startDate: Time.parseDate(timeframe.startDate),
    endDate: Time.parseDate(timeframe.endDate),
    type: timeframe.type as TimeframeType,
  };
}

//
// Formatting the timeframe for display
//

export function format(timeframe: Timeframe) {
  return match(timeframe.type)
    .with("month", () => formatMonth(timeframe))
    .with("quarter", () => formatQuarter(timeframe))
    .with("year", () => formatYear(timeframe))
    .with("days", () => formatDays(timeframe))
    .exhaustive();
}

function formatMonth(timeframe: Timeframe) {
  if (!timeframe.startDate) return null;
  if (!timeframe.endDate) return null;

  return timeframe.startDate.toLocaleString("default", { month: "long", year: "numeric" });
}

function formatQuarter(timeframe: Timeframe) {
  const quarter = Math.floor(timeframe.startDate!.getMonth() / 3) + 1;
  return `Q${quarter} ${timeframe.startDate!.getFullYear()}`;
}

function formatYear(timeframe: Timeframe) {
  if (!timeframe.startDate) return null;

  return timeframe.startDate.getFullYear().toString();
}

function formatDays(timeframe: Timeframe) {
  if (!timeframe.startDate) return null;
  if (!timeframe.endDate) return null;

  if (timeframe.startDate.getFullYear() === timeframe.endDate.getFullYear()) {
    if (Time.today().getFullYear() === timeframe.startDate.getFullYear()) {
      const start = timeframe.startDate.toLocaleString("default", { month: "long", day: "numeric" });
      const end = timeframe.endDate.toLocaleString("default", { month: "long", day: "numeric" });

      return `${start} - ${end}`;
    } else {
      const start = timeframe.startDate.toLocaleString("default", { month: "long", day: "numeric" });
      const end = timeframe.endDate.toLocaleString("default", { month: "long", day: "numeric", year: "numeric" });

      return `${start} - ${end}`;
    }
  } else {
    const start = timeframe.startDate.toLocaleString("default", { month: "long", day: "numeric", year: "numeric" });
    const end = timeframe.endDate.toLocaleString("default", { month: "long", day: "numeric", year: "numeric" });

    return `${start} - ${end}`;
  }
}

//
// Shortcut functions for creating timeframes
//

export function firstQuarterOfYear(year: number): Timeframe {
  return {
    startDate: new Date(year, 0, 1),
    endDate: new Date(year, 2, 31),
    type: "quarter",
  };
}

export function secondQuarterOfYear(year: number): Timeframe {
  return {
    startDate: new Date(year, 3, 1),
    endDate: new Date(year, 5, 30),
    type: "quarter",
  };
}

export function thirdQuarterOfYear(year: number): Timeframe {
  return {
    startDate: new Date(year, 6, 1),
    endDate: new Date(year, 8, 30),
    type: "quarter",
  };
}

export function fourthQuarterOfYear(year: number): Timeframe {
  return {
    startDate: new Date(year, 9, 1),
    endDate: new Date(year, 11, 31),
    type: "quarter",
  };
}

//
// Duration calculations
//

export function dayCount(timeframe: Timeframe): number {
  if (!timeframe.startDate) return 0;
  if (!timeframe.endDate) return 0;

  const startDate = typeof timeframe.startDate === "string" ? new Date(timeframe.startDate) : timeframe.startDate;
  const endDate = typeof timeframe.endDate === "string" ? new Date(timeframe.endDate) : timeframe.endDate;

  return Time.daysBetween(startDate, endDate);
}

export function hasOverlap(a: Timeframe, b: Timeframe): boolean {
  return Time.compareAsc(a.startDate, b.endDate) <= 0 && Time.compareAsc(b.startDate, a.endDate) <= 0;
}

//
// Comparison functions
//

export function equalDates(a: Timeframe, b: Timeframe): boolean {
  if (!a.startDate || !b.startDate) return false;
  if (!a.endDate || !b.endDate) return false;

  return Time.isSameDay(a.startDate, b.startDate) && Time.isSameDay(a.endDate, b.endDate);
}

export function compareDuration(a: Timeframe, b: Timeframe): number {
  if (!a.startDate || !b.startDate) return 0;
  if (!a.endDate || !b.endDate) return 0;

  const aDuration = Time.daysBetween(a.startDate, a.endDate);
  const bDuration = Time.daysBetween(b.startDate, b.endDate);

  if (aDuration < bDuration) return 1;
  if (aDuration > bDuration) return -1;

  return 0;
}
