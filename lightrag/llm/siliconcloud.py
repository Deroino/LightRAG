import sys
import traceback

if sys.version_info < (3, 9):
    from typing import AsyncIterator
else:
    from collections.abc import AsyncIterator

import pipmaster as pm  # Pipmaster for dynamic library install

# install specific modules
if not pm.is_installed("aiohttp"):
    pm.install("aiohttp")

from openai import (
    APIConnectionError,
    RateLimitError,
    APITimeoutError,
)
from tenacity import (
    retry,
    stop_after_attempt,
    wait_exponential,
    retry_if_exception_type,
)
from lightrag.utils import (
    safe_unicode_decode,
    logger,
    locate_json_string_body_from_string,
)
from lightrag.api import __api_version__

import numpy as np
import aiohttp
import base64
import struct
import json
from typing import Union, Any


class InvalidResponseError(Exception):
    """Custom exception class for triggering retry mechanism"""
    pass


@retry(
    stop=stop_after_attempt(3),
    wait=wait_exponential(multiplier=1, min=4, max=60),
    retry=retry_if_exception_type(
        (RateLimitError, APIConnectionError, APITimeoutError, InvalidResponseError)
    ),
)
async def siliconcloud_embedding(
    texts: list[str],
    model: str = "netease-youdao/bce-embedding-base_v1",
    base_url: str = "https://api.siliconflow.cn/v1/embeddings",
    max_token_size: int = 8192,
    api_key: str = None,
) -> np.ndarray:
    if api_key and not api_key.startswith("Bearer "):
        api_key = "Bearer " + api_key

    headers = {"Authorization": api_key, "Content-Type": "application/json"}

    truncate_texts = [text[0:max_token_size] for text in texts]

    payload = {"model": model, "input": truncate_texts, "encoding_format": "float"}

    # Ensure the base_url ends with /embeddings
    if not base_url.endswith("/embeddings"):
        if base_url.endswith("/"):
            base_url = base_url + "embeddings"
        else:
            base_url = base_url + "/embeddings"

    async with aiohttp.ClientSession() as session:
        async with session.post(base_url, headers=headers, json=payload) as response:
            if response.status != 200:
                error_text = await response.text()
                logger.error(f"SiliconCloud Embedding API Error {response.status}: {error_text}")
                if response.status == 404:
                    raise InvalidResponseError(f"Embedding API endpoint not found: {error_text}")
                elif response.status == 401:
                    raise InvalidResponseError(f"Invalid API key: {error_text}")
                elif response.status == 429:
                    raise InvalidResponseError(f"Rate limit exceeded: {error_text}")
                else:
                    raise InvalidResponseError(f"HTTP {response.status}: {error_text}")
            
            try:
                content = await response.json()
            except aiohttp.ContentTypeError as e:
                error_text = await response.text()
                logger.error(f"Failed to parse JSON response: {error_text}")
                raise InvalidResponseError(f"Invalid JSON response: {error_text}")
            
            if "error" in content:
                logger.error(f"SiliconCloud Embedding API Error: {content['error']}")
                raise InvalidResponseError(f"API Error: {content['error']}")
            
            if "code" in content:
                logger.error(f"SiliconCloud Embedding API Error Code: {content}")
                raise InvalidResponseError(f"API Error Code: {content}")
            
            if "data" not in content or not content["data"]:
                logger.error("Invalid response: no data found")
                raise InvalidResponseError("Invalid response: no data found")
            
            embeddings = []
            for item in content["data"]:
                if "embedding" not in item:
                    logger.error("Invalid response: no embedding found in data item")
                    raise InvalidResponseError("Invalid response: no embedding found in data item")
                embeddings.append(item["embedding"])
            
            return np.array(embeddings)


@retry(
    stop=stop_after_attempt(3),
    wait=wait_exponential(multiplier=1, min=4, max=10),
    retry=(
        retry_if_exception_type(RateLimitError)
        | retry_if_exception_type(APIConnectionError)
        | retry_if_exception_type(APITimeoutError)
        | retry_if_exception_type(InvalidResponseError)
    ),
)
async def siliconcloud_complete_if_cache(
    model: str,
    prompt: str,
    system_prompt: str | None = None,
    history_messages: list[dict[str, Any]] | None = None,
    base_url: str | None = None,
    api_key: str | None = None,
    token_tracker: Any | None = None,
    keyword_extraction: bool = False,
    **kwargs: Any,
) -> str:
    """Complete a prompt using SiliconCloud's API with caching support.

    Args:
        model: The SiliconCloud model to use.
        prompt: The prompt to complete.
        system_prompt: Optional system prompt to include.
        history_messages: Optional list of previous messages in the conversation.
        base_url: Optional base URL for the SiliconCloud API.
        api_key: Optional SiliconCloud API key.
        token_tracker: Optional token tracker for usage monitoring.
        **kwargs: Additional keyword arguments to pass to the SiliconCloud API.

    Returns:
        The completed text or an async iterator of text chunks if streaming.

    Raises:
        InvalidResponseError: If the response from SiliconCloud is invalid or empty.
        APIConnectionError: If there is a connection error with the SiliconCloud API.
        RateLimitError: If the SiliconCloud API rate limit is exceeded.
        APITimeoutError: If the SiliconCloud API request times out.
    """
    
    if history_messages is None:
        history_messages = []

    # Set default base URL if not provided
    if base_url is None:
        base_url = "https://api.siliconflow.cn/v1/chat/completions"
    else:
        # 确保base_url以正确的端点结尾
        if not base_url.endswith("/chat/completions"):
            if base_url.endswith("/"):
                base_url = base_url + "chat/completions"
            else:
                base_url = base_url + "/chat/completions"
    

    # Prepare headers
    headers = {
        "Content-Type": "application/json",
        "User-Agent": f"LightRAG/{__api_version__}",
    }
    
    if api_key:
        if not api_key.startswith("Bearer "):
            api_key = "Bearer " + api_key
        headers["Authorization"] = api_key

    # Remove special kwargs that shouldn't be passed to SiliconCloud
    kwargs.pop("hashing_kv", None)
    kwargs.pop("base_url", None)
    kwargs.pop("api_key", None)
    # 强制禁用流式响应
    kwargs.pop("stream", None)

    # Prepare messages
    messages: list[dict[str, Any]] = []
    if system_prompt:
        messages.append({"role": "system", "content": system_prompt})
    messages.extend(history_messages)
    messages.append({"role": "user", "content": prompt})

    # Prepare payload
    payload = {
        "model": model,
        "messages": messages,
        **kwargs
    }

    logger.debug("===== Entering func of SiliconCloud LLM =====")
    logger.debug(f"Model: {model}   Base URL: {base_url}")
    logger.debug(f"Additional kwargs: {kwargs}")
    logger.debug(f"Num of history messages: {len(history_messages)}")
    logger.debug("===== Sending Query to SiliconCloud LLM =====")

    try:
        timeout = aiohttp.ClientTimeout(total=kwargs.get("timeout", 300))
        async with aiohttp.ClientSession(timeout=timeout) as session:
            async with session.post(base_url, headers=headers, json=payload) as response:
                if response.status != 200:
                    error_text = await response.text()
                    logger.error(f"SiliconCloud API Error {response.status}: {error_text}")
                    if response.status == 429:
                        raise InvalidResponseError(f"Rate limit exceeded: {error_text}")
                    elif response.status in [502, 503, 504]:
                        raise InvalidResponseError(f"Server error {response.status}: {error_text}")
                    else:
                        raise InvalidResponseError(f"HTTP {response.status}: {error_text}")

                # 强制使用非流式响应，因为LightRAG缓存系统不支持AsyncIterator
                return await _handle_non_streaming_response(response, token_tracker, keyword_extraction)

    except aiohttp.ClientError as e:
        logger.error(f"SiliconCloud API Connection Error: {e} \n {traceback.format_exc()}")
        raise Exception(f"Connection failed: {e}")
    except Exception as e:
        logger.error(f"SiliconCloud API Call Failed: {e} \n {traceback.format_exc()}")
        raise


async def _handle_non_streaming_response(
    response: aiohttp.ClientResponse, 
    token_tracker: Any = None, 
    keyword_extraction: bool = False
) -> str:
    """Handle non-streaming response from SiliconCloud API"""
    try:
        content = await response.json()
        
        if "error" in content:
            logger.error(f"SiliconCloud API Error: {content['error']}")
            raise InvalidResponseError(f"API Error: {content['error']}")

        if not content.get("choices") or not content["choices"]:
            logger.error("Invalid response: no choices found")
            raise InvalidResponseError("Invalid response: no choices found")

        choice = content["choices"][0]
        if "message" not in choice or "content" not in choice["message"]:
            logger.error("Invalid response: no message content found")
            raise InvalidResponseError("Invalid response: no message content found")

        text_content = choice["message"]["content"]
        
        if not text_content or text_content.strip() == "":
            logger.error("Received empty content from SiliconCloud API")
            raise InvalidResponseError("Received empty content from SiliconCloud API")

        # Handle unicode encoding
        if r"\u" in text_content:
            text_content = safe_unicode_decode(text_content.encode("utf-8"))

        # Track token usage if available
        if token_tracker and "usage" in content:
            usage = content["usage"]
            token_counts = {
                "prompt_tokens": usage.get("prompt_tokens", 0),
                "completion_tokens": usage.get("completion_tokens", 0),
                "total_tokens": usage.get("total_tokens", 0),
            }
            token_tracker.add_usage(token_counts)
            logger.debug(f"Token usage: {token_counts}")

        # Handle keyword extraction
        if keyword_extraction:
            return locate_json_string_body_from_string(text_content)

        logger.debug(f"Response content len: {len(text_content)}")
        return text_content

    except json.JSONDecodeError as e:
        logger.error(f"Failed to parse JSON response: {e}")
        raise InvalidResponseError(f"Invalid JSON response: {e}")


async def _handle_streaming_response(
    response: aiohttp.ClientResponse, 
    token_tracker: Any = None, 
    keyword_extraction: bool = False
) -> AsyncIterator[str]:
    """Handle streaming response from SiliconCloud API"""
    
    async def inner():
        try:
            collected_content = ""
            async for line in response.content:
                line_str = line.decode("utf-8").strip()
                
                if not line_str:
                    continue
                    
                if line_str.startswith("data: "):
                    data_str = line_str[6:]  # Remove "data: " prefix
                    
                    if data_str == "[DONE]":
                        break
                    
                    try:
                        data = json.loads(data_str)
                        
                        if "error" in data:
                            logger.error(f"Streaming error: {data['error']}")
                            raise InvalidResponseError(f"Streaming error: {data['error']}")
                        
                        if "choices" in data and data["choices"]:
                            choice = data["choices"][0]
                            if "delta" in choice and "content" in choice["delta"]:
                                content = choice["delta"]["content"]
                                if content:
                                    if r"\u" in content:
                                        content = safe_unicode_decode(content.encode("utf-8"))
                                    collected_content += content
                                    yield content
                        
                        # Track token usage from final chunk
                        if token_tracker and "usage" in data:
                            usage = data["usage"]
                            token_counts = {
                                "prompt_tokens": usage.get("prompt_tokens", 0),
                                "completion_tokens": usage.get("completion_tokens", 0),
                                "total_tokens": usage.get("total_tokens", 0),
                            }
                            token_tracker.add_usage(token_counts)
                            logger.debug(f"Streaming token usage: {token_counts}")
                            
                    except json.JSONDecodeError:
                        # Skip malformed JSON lines
                        continue
            
            # Handle keyword extraction for streaming
            if keyword_extraction and collected_content:
                # For streaming, we need to yield the final JSON extraction
                extracted = locate_json_string_body_from_string(collected_content)
                yield extracted
                
        except Exception as e:
            logger.error(f"Error in streaming response: {str(e)}")
            raise

    return inner()


async def siliconcloud_complete(
    prompt,
    system_prompt=None,
    history_messages=None,
    keyword_extraction=False,
    **kwargs,
) -> Union[str, AsyncIterator[str]]:
    """SiliconCloud completion function following LightRAG convention"""
    if history_messages is None:
        history_messages = []
    
    keyword_extraction = kwargs.pop("keyword_extraction", keyword_extraction)
    model_name = kwargs["hashing_kv"].global_config["llm_model_name"]
    
    return await siliconcloud_complete_if_cache(
        model_name,
        prompt,
        system_prompt=system_prompt,
        history_messages=history_messages,
        keyword_extraction=keyword_extraction,
        **kwargs,
    )
