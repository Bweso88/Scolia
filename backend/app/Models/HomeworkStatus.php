<?php

namespace App\Models;

use App\Models\Concerns\BelongsToTenant;
use Database\Factories\HomeworkStatusFactory;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class HomeworkStatus extends Model
{
    /** @use HasFactory<HomeworkStatusFactory> */
    use BelongsToTenant, HasFactory;

    protected $table = 'homework_status';

    protected $fillable = ['homework_id', 'student_id', 'status', 'marked_by_user_id'];

    public function homework(): BelongsTo
    {
        return $this->belongsTo(Homework::class);
    }

    public function student(): BelongsTo
    {
        return $this->belongsTo(Student::class);
    }

    public function markedBy(): BelongsTo
    {
        return $this->belongsTo(User::class, 'marked_by_user_id');
    }
}
