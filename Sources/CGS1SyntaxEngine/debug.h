/**
 * GS1 Barcode Syntax Engine
 *
 * @author Copyright (c) 2021-2024 GS1 AISBL.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 *
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 */

#ifndef DEBUG_H
#define DEBUG_H

#include <stdint.h>


#if PRNT

#define DEBUG_PRINT(...) do {				\
	printf(__VA_ARGS__);				\
} while (0)


#else

#define DEBUG_PRINT(...) {}

#endif  /* PRNT */


#endif  /* DEBUG_H */
