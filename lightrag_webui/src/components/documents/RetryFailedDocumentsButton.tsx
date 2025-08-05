import { useState, useCallback } from 'react'
import Button from '@/components/ui/Button'
import { toast } from 'sonner'
import { errorMessage } from '@/lib/utils'
import { retryFailedDocuments } from '@/api/lightrag'
import { RotateCcwIcon } from 'lucide-react'
import { useTranslation } from 'react-i18next'

interface RetryFailedDocumentsButtonProps {
  failedCount: number
  onRetryCompleted?: () => Promise<void>
}

export default function RetryFailedDocumentsButton({ 
  failedCount, 
  onRetryCompleted 
}: RetryFailedDocumentsButtonProps) {
  const { t } = useTranslation()
  const [isRetrying, setIsRetrying] = useState(false)

  const handleRetry = useCallback(async () => {
    if (failedCount === 0) {
      toast.message(t('documentPanel.retryFailedDocuments.noFailedDocuments'))
      return
    }

    setIsRetrying(true)
    
    try {
      // 显示开始重试的提示
      toast.message(t('documentPanel.retryFailedDocuments.retrying'))
      
      // 调用重试失败文档API
      const result = await retryFailedDocuments()
      
      // 根据响应状态显示不同消息
      switch (result.status) {
        case 'retry_started':
          toast.success(t('documentPanel.retryFailedDocuments.success', { 
            count: result.failed_count || 0 
          }))
          break
        case 'no_failed_documents':
          toast.message(t('documentPanel.retryFailedDocuments.noFailedDocuments'))
          break
        case 'busy':
          toast.warning(t('documentPanel.retryFailedDocuments.busy'))
          break
        default:
          toast.success(result.message)
      }
      
      // 只有在成功启动重试时才刷新文档列表
      if (result.status === 'retry_started' && onRetryCompleted) {
        await onRetryCompleted()
      }
    } catch (err) {
      toast.error(t('documentPanel.retryFailedDocuments.error', { error: errorMessage(err) }))
    } finally {
      setIsRetrying(false)
    }
  }, [failedCount, onRetryCompleted, t])

  return (
    <Button
      variant="outline"
      onClick={handleRetry}
      disabled={failedCount === 0 || isRetrying}
      side="bottom"
      tooltip={
        failedCount === 0 
          ? t('documentPanel.retryFailedDocuments.noFailedTooltip')
          : t('documentPanel.retryFailedDocuments.tooltip', { count: failedCount })
      }
      size="sm"
    >
      <RotateCcwIcon className={isRetrying ? 'animate-spin' : ''} />
      {t('documentPanel.retryFailedDocuments.button')}
    </Button>
  )
}