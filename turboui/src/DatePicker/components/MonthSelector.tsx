import React, { useRef, useLayoutEffect } from "react";
import { generateMonths } from "../utils";
import { OptionButton } from "./OptionButton";

interface Props {
  selectedDate: Date | undefined;
  setSelectedDate: (date: Date | undefined) => void;
  visibleYears: number[];
}

export function MonthSelector({ selectedDate, setSelectedDate, visibleYears }: Props) {
  const currentYear = new Date().getFullYear(); // Should be 2025
  const containerRef = useRef<HTMLDivElement | null>(null);

  useLayoutEffect(() => {
    setSelectedDate(undefined);
    const currentYearIndex = visibleYears.indexOf(currentYear);

    if (currentYearIndex !== -1 && containerRef.current) {
      const totalYears = visibleYears.length;

      // Calculate the scroll percentage (0 to 1) where current year should be positioned
      // For example, if 2025 is the middle year in 2020-2030 range, percentage would be ~0.5
      const scrollPercentage = currentYearIndex / (totalYears - 1);

      // Get scrollable height
      const scrollHeight = containerRef.current.scrollHeight - containerRef.current.clientHeight;

      containerRef.current.scrollTop = scrollHeight * scrollPercentage;
    }
  }, []);

  return (
    <div className="mb-3">
      <div ref={containerRef} className="max-h-48 overflow-y-auto p-2">
        {visibleYears.map((year) => (
          <div key={year} className="mb-4 last:mb-0">
            <div className="text-xs font-medium text-gray-500 mb-1">{year}</div>
            <div className="grid grid-cols-4 gap-1">
              {generateMonths(year).map((month) => (
                <OptionButton
                  key={month.value}
                  onClick={() => {
                    setSelectedDate(new Date(month.value));
                  }}
                  isSelected={isSelectedMonth(selectedDate, month.value, year)}
                  className="py-1 px-2 text-xs"
                >
                  {month.label}
                </OptionButton>
              ))}
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}

function isSelectedMonth(date: Date | undefined, monthValue: string, year: number): boolean {
  try {
    if (!date) return false;

    const monthDate = new Date(monthValue);
    return (
      date.getFullYear() === year &&
      date.getFullYear() === monthDate.getFullYear() &&
      date.getMonth() === monthDate.getMonth()
    );
  } catch {
    return false;
  }
}
